clearListener()


fn copyUVCoords obj srcUV destUV = (
	try (
		local channel_type = 3		-- Map
		channelInfo.copyChannel obj channel_type srcUV
		channelInfo.addChannel obj
		channelInfo.pasteChannel obj channel_type destUV
		channelInfo.NameChannel obj channel_type destUV "-none-"
		maxOps.CollapseNode obj true		
	)
	catch()
)

fn moveUVCoords obj srcUV destUV = (
	try (
		local channel_type = 3		-- Map
		channelInfo.copyChannel obj channel_type srcUV
		channelInfo.pasteChannel obj channel_type destUV
		channelInfo.clearChannel obj srcUV
		maxOps.CollapseNode obj true		
	)
	catch()
)

fn renderToTextureObjMaterial obj size target_channel = (
	if obj == undefined then return false
	obj.iNodeBakeProperties.removeAllBakeElements()

	--instance of the bake element classm
	local be1 = diffusemap()	
	
	-- Set details of output baked elem
	be1.outputSzX = be1.outputSzY = size
	be1.fileType = (getDir #image+"\\"+obj.name+"_remap.tga")
	be1.fileName = filenameFromPath be1.fileType
	be1.filterOn = true
	be1.shadowsOn = false
	be1.lightingOn = false
	be1.enabled = true
	be1.elementname = "DiffuseMap"
	be1.targetMapSlotName = "Diffuse Color" 
	
	obj.INodeBakeProperties.addBakeElement be1 
	obj.INodeBakeProperties.bakeEnabled = true
	obj.INodeBakeProperties.bakeChannel = target_channel	-- Which channel to use
	obj.INodeBakeProperties.nDilations = 4					-- Padding
	
	select obj
	
	format "Rendering to %\n" be1.fileType
	render rendertype:#bakeSelected vfb:off progressBar:true outputSize:[size,size]
	return be1.fileType
)

fn deleteAllModifiers obj = (
	while obj.modifiers.count != 0 do  deleteModifier obj 1
)

fn remapObject the_obj new_channel = (
	
	local newUVW = Unwrap_UVW()
	
	-- Do a full copy of UV1 to start from
	copyUVCoords obj 1 new_channel
	
	newUVW.setMapChannel new_channel
	
	addmodifier obj newUVW
	
	-- 1 -> Recursive algorithm
	-- Spacing amountm
	-- Normalize | Rotate | Fill holes
	newUVW.pack 1 0.0 true true true
	
	-- Collapse the stack
	maxOps.CollapseNode obj true
	
	return obj
)

fn collapseDiffuse obj = (
	deleteAllModifiers obj
	remapObject obj 3
	local new_filename = renderToTextureObjMaterial obj 512 3
	moveUVCoords obj 3 1
	obj.mat = standard diffusemap:(bitmaptexture filename:new_filename name:"MapDiffuse")
	obj.mat.showInViewport = on
)

obj = $Teapot002
collapseDiffuse obj