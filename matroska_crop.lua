local msg = require 'mp.msg'
local utils = require 'mp.utils'
require 'mp.options'

-- HELPER FUNCTIONS
function map(array, func)
    local mapped = {}

    for k, v in pairs(array) do
        mapped[k] = func(v)
    end

    return mapped
end

function filter(array, func)
    local filtered = {}

    for k, v in pairs(array) do
        if func(v) then
            table.insert(filtered, v)
        end
    end

    return filtered
end

function split(s, delim)
    local fields = {}
    local pattern = string.format('([^%s]+)', delim)

    s:gsub(pattern, function(c) table.insert(fields, c) end)

    return fields
end

-- MAIN FUNCIONS
function handle_file_load()
    filepath = mp.get_property('path')
    -- check if filepath
    --  * does not includes protocol handler (http, av) which mkvmerge cannot handle
    --  * ends with mkv extension
    if string.find(filepath, '://') == nil and filepath:sub(-4) == ".mkv" then
        mp.unobserve_property(handle_vid_change)
        mp.observe_property('vid', 'number', handle_vid_change)
    end
end

function handle_vid_change()
    local vid = mp.get_property_number('vid')

    if vid ~= nil then
        local cropping = get_cropping(filepath, vid)
        if cropping ~= nil then
            if options.dynamic_hwdec == true then
                mp.set_property('hwdec', 'none')
            end
            crop_filter = string.format('@matroska-crop:crop=w=in_w-%d:h=in_h-%d:x=%d:y=%d', cropping['left'] + cropping['right'], cropping['top'] + cropping['bottom'], cropping['left'], cropping['top'])
            mp.command_native({'vf', 'add', crop_filter})
        else
            if options.dynamic_hwdec == true then
                if mp.get_property('hwdec') == 'none' then
                    mp.command_native({'vf', 'add', '@matroska-crop:eq'})
                    mp.command_native({'vf', 'del', '@matroska-crop'})
                end
                mp.set_property('hwdec', default_hwdec)
            end
        end
    end
end

function get_cropping(filepath, vid)
    -- not using mp.command_native, because it does not support capturing stdout in mpv from debian testing (as of writing this)
    local mkvmerge_run = utils.subprocess({args={'mkvmerge', '-J', filepath}})
    if mkvmerge_run.err ~= nil then
        msg.error(mkvmerge_run.err)
        return nil
    end

    -- this happens if scrolling through a playlist fast
    if mkvmerge_run.stdout == '' then
        return nil
    end

    local data, err = utils.parse_json(mkvmerge_run.stdout)

    if err ~= nil then
        msg.error(err)
        return nil
    end

    local tracks = data.tracks
    local video_tracks = filter(data.tracks, function(track) return track.type == 'video' end)
    local video_track = video_tracks[vid].properties

    if video_track.cropping == nil then
        return nil
    end

    local cropping = map(split(video_track.cropping, ','), tonumber)

    return {
        ['left'] = cropping[1],
        ['top'] = cropping[2],
        ['right'] = cropping[3],
        ['bottom'] = cropping[4],
    }
end

options = {
    dynamic_hwdec = false,
}
read_options(options)

if options.dynamic_hwdec then
    default_hwdec = mp.get_property('hwdec')
    mp.register_event('file-loaded', handle_file_load)
else
    if mp.get_property('hwdec') == 'none' then
        mp.register_event('file-loaded', handle_file_load)
    end
end
