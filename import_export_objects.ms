clearListener()

struct TIOFiles (
	root_folder = (getdir #scene)
, 	extension = ".fbx"
,	function exportToFile objs filename = (
		format "Exporting to % %\n" filename objs
		local ofilename = root_folder + "/" + filename + extension
		local final_objs = #()
		local objs_created = #()
		local fname = filename
		for obj in objs do (
			local new_obj = obj
			-- Resolve xref dependencies
			if classof obj == XRefObject then (
				new_obj = copy obj
				new_obj.name = obj.name
				convertToMesh new_obj
				append objs_created new_obj
			)
			if classof obj.mat == XRef_Material then (
				local new_mat = copy obj.mat
				new_obj.mat = new_mat.GetSrcItem()
			)
			-- collapse stack...
			append final_objs new_obj
		)
		select final_objs
		exportFile ofilename #noprompt selectedOnly:true
		clearSelection()
		delete objs_created 
	)
	-------------------------------------
	, fn importFromFilesAndSubFoldersAndApply callback folder: depth:0 = (
		local use_folder = root_folder
		if folder != unsupplied then use_folder = folder
			
		-- Scan files, and apply the callback to each file
		local files = getFiles (use_folder + "/*" + extension)
		for f in files do (
			callback f
		)
		-- Now children folders
		local folders = getDirectories (use_folder + "/*")
		for f in folders do (
			format "Entering subfolder %\n" f
			importFromFilesAndSubFoldersAndApply callback folder:f depth:(depth+1)
			format "Leaving subfolder %\n" f
		)
	)
)

-------------------------------------
fn doImportFile infile = (
	format "Importing file %\n" infile
	resetMaxFile #noPrompt 
	importFile infile #noprompt 
)

-------------------------------------
fn testExport = (
	local ef = TIOFiles root_folder:(getDir #scene)
	ef.exportToFile ($John* as array) "exported_john"
	ef.exportToFile ($Box* as array) "exported_box"
)

fn testImport = (
	local ef = TIOFiles root_folder:(getDir #scene)
	ef.importFromFilesAndSubFoldersAndApply doImportFile
)

--testExport()
testImport()
