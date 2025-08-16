--[[

This is an export script for Aseprite

It takes the currently selected layer and exports it into ../res/images/layername.png

Or, if it's an animation, will export all animation tags to ../res/images/spritename_tagname.png

Very helpful for quickly exporting with a keybind.

]]

local spr = app.activeSprite
if not spr then return print('No active sprite') end

-- Extract the current path and filename of the active sprite
local local_path, title, extension = spr.filename:match("^(.+[/\\])(.-)(%.[^.]*)$")

-- Construct export path by prefixing the current .aseprite file path
local export_path = local_path .. "../assets/"
local_path = export_path

local sprite_name = app.fs.fileTitle(app.activeSprite.filename)

function layer_export()
  local fn = local_path .. "/" .. app.activeLayer.name
  app.command.ExportSpriteSheet{
      ui=false,
      type=SpriteSheetType.HORIZONTAL,
      textureFilename=fn .. '.png',
      dataFormat=SpriteSheetDataFormat.JSON_ARRAY,
      layer=app.activeLayer.name,
      trim=true,
  }
end

local asset_path = local_path .. '/'

function do_animation_export()
  for i,tag in ipairs(spr.tags) do
    local fn =  asset_path .. sprite_name .. "_" .. tag.name
    app.command.ExportSpriteSheet{
      ui=false,
      type=SpriteSheetType.HORIZONTAL,
      textureFilename=fn .. '.png',
      dataFormat=SpriteSheetDataFormat.JSON_ARRAY,
      tag=tag.name,
      listLayers=false,
      listTags=false,
      listSlices=false,
    }
  end
end

if #spr.tags > 0 then
  do_animation_export()
else 
  layer_export()
end
