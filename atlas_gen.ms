-- Author: Juan Abadia  (juan.abadia@gmail.com)
-- Date: 2015-07-19

struct TAtlasTask (
	obj, target_slot, faces 
)

struct TAtlasGen (
	in_materials = #()
, 	map_channel = 1
,  	out_resolution = 512
, 	out_atlas_size = 8			-- 8 x 8
, 	out_inv_scale = 1. / out_atlas_size
, 	out_material
, 	out_path = (getDir #image)
, 	out_prefix = "atlas"
, 	out_ext = ".tga"
,   tasks = #()
----------------------------------------
, 	function materialsAreEqual m1 m2 = (
		return m1.name == m2.name
)
----------------------------------------
, 	function registerMat mat = (
	if classof mat != standardmaterial then throw "Mat should be standard"
	local idx = 0
	for m in in_materials do (
		if materialsAreEqual m mat then return idx
		idx = idx + 1
	)
	append in_materials mat
	--format "Registering mat % as %\n" (in_materials.count-1) mat.name
	return (in_materials.count-1)
)

----------------------------------------
, 	mapped function generateTasks obj = (
	
	if classof obj != editable_mesh then return false
	
	-- Collect how many faces per material id is using this obj
	local faces_by_mat_id = #()
	local face_id
	local num_faces = getNumfaces obj
	for face_id = 1 to num_faces do (
		local mat_id = getfacematid obj face_id
		if faces_by_mat_id[mat_id] == undefined then (
			faces_by_mat_id[mat_id] = #()
		)
		append faces_by_mat_id[mat_id] face_id
	)
	
	-- Now generate a task for each group
	-- register each material as we found news
	local mat_id
	for mat_id = 1 to faces_by_mat_id.count do (
		local g = faces_by_mat_id[ mat_id ]
		if g == undefined then continue
		local mat = obj.mat
		if classof mat == multimaterial then (
			mat = mat[ mat_id ]
		)
		local slot = registerMat mat
		format "Mat_id % is % -> slot %\n" mat_id mat.name slot
		
		local t = TAtlasTask obj:obj faces:g target_slot:slot
		append tasks t
	)
	
	return true
)

----------------------------------------
,   function getICoordsOfSlot slot = (
	return [mod slot out_atlas_size, (slot / out_atlas_size) as integer]
)

----------------------------------------
,   function getAtlasPixelCoordsOfSlot slot = (
	local c = getICoordsOfSlot slot
	return c * out_resolution / out_atlas_size
)

----------------------------------------
,   function getAtlasUnitCoordsOfSlot slot = (
	local c = getICoordsOfSlot slot
	return c / out_atlas_size
)

----------------------------------------
-- material_slot should be "diffuseMap" for example
,   function generateMap material_slot = (
	local sufix = "_alb"
	if material_slot == "bumpMap" then sufix = "_n"
	if material_slot == "selfIllumMap" then sufix = "_st"
	if material_slot == "specularLevelMap" then sufix = "_brdf"
		
	local out_filename = out_path + "/" + out_prefix + sufix + out_ext
	local out_bitmap = Bitmap out_resolution out_resolution color:gray filename:out_filename
	local slot_res = out_resolution / out_atlas_size
	local scaled_bitmap = Bitmap slot_res slot_res
	local idx = 0
	for m in in_materials do (
		local ic = getAtlasPixelCoordsOfSlot idx
		local texture = getproperty m material_slot
		if texture != undefined then (
			copy texture.bitmap scaled_bitmap
			pasteBitmap scaled_bitmap out_bitmap [0,0] ic type:#paste
		)
		idx = idx + 1
	)
	save out_bitmap
	
	local map = Bitmaptexture filename:out_filename
	return map
)

----------------------------------------
-- material_slot should be "diffuseMap" for example
,   function generateMaterial = (
	local maps = #( "diffuseMap", "bumpMap", "selfIllumMap", "specularLevelMap" )
	local new_mat = standard()
	for map_property in maps do (
		local new_map = generateMap map_property
		display new_map.bitmap
		setproperty new_mat map_property new_map
	)
	--local m = standard diffusemap:diffuse_map bumpmap:bump_map
	new_mat.showInViewport = on
	return new_mat
)

----------------------------------------
, 	mapped function executeTasksOfObject obj = (
	if obj == undefined then return false

	-- Remove previous modifiers.. or collapse
	while obj.modifiers.count > 0 do deletemodifier obj 1
	
	-- Add a new UVW
	local uvw = Unwrap_UVW()
	uvw.setMapChannel map_channel
	addmodifier obj uvw
	select obj
	subobjectLevel = 3 
	
	for t in tasks do (
		if t.obj != obj then continue

		local faces = t.faces as bitarray
		uvw.selectFaces faces
		uvw.scaleSelectedXY out_inv_scale out_inv_scale [0,0,0]
		local uc = getAtlasUnitCoordsOfSlot t.target_slot
		local offset = [uc[1], 1-out_inv_scale-uc[2], 0]
		uvw.moveSelected offset
	)
	
	subobjectLevel = 0
)

----------------------------------------
, 	function generate objs = (
	
	in_materials = #()
	tasks = #()

	generateTasks objs

	-- Check we don't need more slots than what we can store in the atlas
	local max_slots = out_atlas_size*out_atlas_size
	if in_materials.count > max_slots then throw ("We need space for " + (in_materials.count as string ) + " but we have just " + (max_slots as string))
	
	executeTasksOfObject objs
	
	out_material = generateMaterial()
	for obj in objs do obj.mat = out_material
)
)

-------------------------------------------
-- Example usage to apply it to the current selected objects
--ag = TAtlasGen out_atlas_size:4
--ag.generate ($* as array)