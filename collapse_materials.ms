
-- Author: Juan Abadia
-- Date: 2015-07-09

struct TCollapseMaterials (
	  resolution = 512
	, tmp_channel = 4
	
	------------------------------------
	, fn copyUVCoords obj srcUV destUV = (
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

	-------------------------------------------
	, fn moveUVCoords obj srcUV destUV = (
		try (
			local channel_type = 3		-- Map
			channelInfo.copyChannel obj channel_type srcUV
			channelInfo.pasteChannel obj channel_type destUV
			channelInfo.clearChannel obj srcUV
			maxOps.CollapseNode obj true		
		)
		catch()
	)

	-------------------------------------------
	, fn renderToTextureObjMaterial obj size target_channel = (
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

	-------------------------------------------
	, fn deleteAllModifiers obj = (
		while obj.modifiers.count != 0 do  deleteModifier obj 1
	)

	-------------------------------------------
	, fn remapObject obj new_channel = (
		
		-- Create a new UVW modifier
		local newUVW = Unwrap_UVW()
		
		-- Do a full copy of UV1 to start from
		copyUVCoords obj 1 new_channel
		
		-- Edit the new channel
		newUVW.setMapChannel new_channel
		
		-- Add it to the object
		addmodifier obj newUVW
		
		-- format "Packing UV's\n"
		-- 1 -> Recursive algorithm
		-- Spacing amountm
		-- Normalize | Rotate | Fill holes
		newUVW.pack 1 0.0 true true true
		
		-- Collapse the stack
		maxOps.CollapseNode obj true
	)

	-- Main entry point
	, fn collapseDiffuse obj = (
		if obj == undefined then return false
		deleteAllModifiers obj

		-- This is not really required
		remapObject obj tmp_channel
		
		local new_filename = renderToTextureObjMaterial obj resolution tmp_channel
		moveUVCoords obj tmp_channel 1

		-- Create a new material with the created texture
		obj.mat = standard diffusemap:(bitmaptexture filename:new_filename name:"MapDiffuse")
		obj.mat.showInViewport = on
	)

)

-------------------------------------------
-- Example usage to apply it to the current selected object
-- cd = TCollapseMaterials resolution:512
-- cd.collapseDiffuse $