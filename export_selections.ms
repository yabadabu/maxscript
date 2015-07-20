-- Author: Juan Abadia  (juan.abadia@gmail.com)
-- Date: 2015-07-19
-- Creates a max for each selection set in the scene. The saveNodes does not work when saving xrefobj's in the scene
-- as the new max has lost the object transform of teach xrefobj.
fn saveSeletionsSetsToFiles out_path: = (
	
	if out_path == unsupplied then out_path = (getDir #scene) + "/selections/"
	makedir out_path all:true
	
	clearListener()
	local st = timestamp()
	try (
		with redraw off (
				
			local nset = selectionsets.count
			for i = 1 to nset do (
				
				local objs = #()
				for obj in selectionSets[i] do append objs obj 
			
				local sel_name = selectionSets[i].name
				format "Saving selection set %\n" sel_name
				--print objs
				
				holdMaxFile()
				undo off (
					select objs
					max select invert
					local other_objs = selection as array
					--print other_objs
					delete other_objs
					
					-- Saving..
					local out_filename = out_path + sel_name + ".max"
					saveMaxfile out_filename quiet:true
				)
				fetchMaxFile quiet:true
			)
		)
	) catch (
		format "Problems exporting: %\n" (getCurrentException())
	)
	(timestamp() - st ) / 1000
)

--saveSeletionsSetsToFiles()