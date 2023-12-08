/*
Texture mapping program

Donghao Zhao
05/02/2022
*/

/* Clear history message in MAXScript Listener */
clearlistener()

/* Texture number to give each texture a unique to break the limit of up to 24 texture spheres */
material_num = 1

/* Working dirctory, everything is under this path */
testure_base_path = "C:\My_Data\Research\SHM_Lab\ROS_Drone_Simulation\Assignment_6\Test\\"

/* Read database file to obtain slicing information */
File_content = (dotnetClass "System.IO.File").ReadAllLines (testure_base_path + "Dividing_Information.txt")

/* Parse the epoch information by the parser "," */
Object_Info = (filterString File_content[1] ",")

/* Convert week number specified in the database file to integer */
week_total_num = Object_Info[2] as integer

/* Convert total object number specified in the database file to integer */
total_object_num = Object_Info[4] as integer


/* For each entry(Object) in the database file, perform slicing and texture mapping, Object information start at line 2, File_content.count */
for file_line_index = 2 to (total_object_num + 1) do 
(
	/**********			Setup			**********/
	
	/* Parse the object information by the parser "," */
	Object_Info = (filterString File_content[file_line_index] ",")
	
	/* The first entry is the name of the object */
	Object_name = Object_Info[1]
	
	/* Find the object that corresponding to the object_name in the 3dMax project */	
	current_object_slicing = execute ("$" + Object_name)
	
	select current_object_slicing
	
	/* Move the pivot of the object to the center of the object */
	CenterPivot current_object_slicing
	
	/* Align the pivot of the object to the world pivot */
	WorldAlignPivot current_object_slicing
	
	/* Reset the pivot configuration to the current pivot, this will permanently change the pivot of the object */
	ResetXForm current_object_slicing
	
	/* Select current object */
	select current_object_slicing
	
	/* Convert current object to a editable polygon, this will overwrite all other history operation and convert the object to a brand new one */
	macros.run "Modifier Stack" "Convert_to_Poly"
	
	/* Added UWM Map modifier to the modifier list of the object */
	modPanel.addModToSelection (Uvwmap ()) ui:on
	
	/* Select the UWM Mapping parameter to "Face" */
	$.modifiers[#UVW_Map].maptype = 5
		
		
	/**********			Slicing			**********/
	
	/* Following info specify how many subspace that we want to slice on every dimention */
	subspace_num_x = Object_Info[2] as integer
	subspace_num_y = Object_Info[3] as integer
	subspace_num_z = Object_Info[4] as integer
	
	/* Use the coordinate of all vertices of the object to form a 4 by 3 matrix */
	verts_pos_matrix = matrix3 current_object_slicing.verts[1].pos current_object_slicing.verts[2].pos current_object_slicing.verts[3].pos current_object_slicing.verts[4].pos
	
	/* Calculate the offset of every dimention */
	offset_matrix = [1,1,1] * verts_pos_matrix * 1/4 - verts_pos_matrix.row1
	
	/* Select current object */
	select current_object_slicing
	
	/* Select "Editable Poly" modifier */
	modPanel.setCurrentObject $.baseObject
	
	/* Select "Polygon" of the "Selection" menu */
	subobjectLevel = 4
	
	/* If the subsurface of x dimention is greater than 1, then perform slicing, otherwise we don't need to slice */
	if subspace_num_x > 1 do
	(
		/* We want subspace_seq_x number of subsurface, we need to perform (subspace_num_x - 1) times of slicing procedure */
		for subspace_seq_x = 1 to (subspace_num_x - 1) do
		(
			/* "2 * offset_matrix.x" is the whole offset of x dimention, divided by subspace_seq_x gives us
				the offset of every subsruface. For each loop, we let the position of the slicing plane move
				alone the x dimention for the length of one offset of the subsurface, subspace_unit_x is the
				position of the slicing plane of x dimention */
			subspace_unit_x = -offset_matrix.x + subspace_seq_x* (2 * offset_matrix.x/subspace_num_x)
			
			/* Perform slicing for every face of the object, faces will increase along the slicing procedure */
			for face_seq in current_object_slicing.faces do
			(
				/* Select a face by the number of the face */
				$.EditablePoly.SetSelection #Face #{face_seq.index}
				
				/* An orthogonal vector and a point where the vector starts at can specify a plane.
					[1,0,0] is the orthogonal vector of the slicing plane, [subspace_unit_x,0,0] is the point where
					the orthogonal vector starts at. flaggedFacesOnly:on means the slicing operation will only affectRegionVal
					the selected faces.
					This will slice the place by a slicing plane, the plane will be divided by the intersection part of
					the two planes. */
				$.EditablePoly.slice [1,0,0] [subspace_unit_x,0,0] flaggedFacesOnly:on
			)
		)
	)
	/* Perform slicing regard to y dimention */
	if subspace_num_y > 1 do
	(
		for subspace_seq_y = 1 to (subspace_num_y - 1) do
		(
			subspace_unit_y = -offset_matrix.y + subspace_seq_y* (2 * offset_matrix.y/subspace_num_y)
			for face_seq in current_object_slicing.faces do
			(
				$.EditablePoly.SetSelection #Face #{face_seq.index}
				$.EditablePoly.slice [0,1,0] [0,subspace_unit_y,0] flaggedFacesOnly:on
			)
		)
	)
	/* Perform slicing regard to z dimention */
	if subspace_num_z > 1 do
	(
		for subspace_seq_z = 1 to (subspace_num_z - 1) do
		(
			subspace_unit_z = -offset_matrix.z + subspace_seq_z* (2 * offset_matrix.z/subspace_num_z)
			for face_seq in current_object_slicing.faces do
			(
				$.EditablePoly.SetSelection #Face #{face_seq.index}
				$.EditablePoly.slice [0,0,1] [0,0,subspace_unit_z] flaggedFacesOnly:on
			)
		)
	)
	
	/* Clear the selection of the "Selection" menu, this is needed for shading procedure */
	subobjectLevel = 0
	
	/* Clear the selection of the current object, this is needed for shading procedure, after this the shading is correct */
	clearSelection()
)



/**********			Texture Mapping			**********/		

/* Using week number to perform Texture Mapping */
for week_num = 1 to week_total_num do
(
	/* For each entry(Object) in the database file, perform slicing and texture mapping, Object information start at line 2, File_content.count */
	for file_line_index = 2 to (total_object_num + 1) do 
	(
		/* Parse the object information by the parser "," */
		Object_Info = (filterString File_content[file_line_index] ",")
		
		/* The first entry is the name of the object */
		Object_name = Object_Info[1]

		/* Following info specify how many subspace that we want to slice on every dimention */
		subspace_num_x = Object_Info[2] as integer
		subspace_num_y = Object_Info[3] as integer
		subspace_num_z = Object_Info[4] as integer
		
		/* Calculate the number of texture files for the current object, which is equal to the number of the subsurface */
		Object_face_num = subspace_num_x * subspace_num_y * subspace_num_z
		
		
		/* Convert current week number from interger to string */
		week_num_string = week_num as string
		
		/* Generate the path that contains the textures of the current object in current epoch(week) */
		work_path = testure_base_path + "Week_" + week_num_string + "\\" + Object_name + "\\"
		
		
		/* For every subsurface whose texture number is the same as the face number of the object, perform texture mapping */
		for texture_num = 1 to Object_face_num do
		(
			/* Convert current texture number from interger to string */
			testure_num_string = texture_num as string
			
			/* Generate the filename of the texture file of the current face */
			texture_file_name = work_path + Object_name + "_Face_" + testure_num_string + "_Week_" + week_num_string + "_Texture.jpg"
			
			/* Print the name of the texture file */
			print texture_file_name
			
			/* Diffuse the texture file to the texture sphere[1] of the material editor of 3dMax*/
			meditMaterials[1].diffuseMap = Bitmaptexture fileName:texture_file_name

			/* Find the object that corresponding to the object_name in the 3dMax project */	
			current_object_mapping = execute ("$" + Object_name)
			
			/* Select current object */
			select current_object_mapping
			
			/* Select "Editable Poly" modifier */
			modPanel.setCurrentObject $.baseObject
			
			/* Select "Polygon" of the "Selection" menu */
			subobjectLevel = 4
			
			/* Select a face by the number specified by the texture file */
			$.EditablePoly.SetSelection #Face #{texture_num}
			
			/* Apply texture to the surface of the object */
			$.material = meditMaterials[1]
			
			/*  */
			meditMaterials[1].name = "Material_" + material_num as string
			
			/*  */
			meditMaterials[1] = copy meditMaterials[1]
			
			/*  */
			meditMaterials[1].shaderType = 1
			
			/*  */
			meditMaterials[1].adTextureLock = on
			
			/*  */
			meditMaterials[1].sampler = 3
			
			/* Texture ID plus one to make sure the material sphere names are different */
			material_num = material_num + 1
		)
		
		/* Clear the selection of the "Selection" menu, this is needed for shading procedure */
		subobjectLevel = 0
		
		/* Clear the selection of the current object, this is needed for shading procedure, after this the shading is correct */
		clearSelection()
		
		/* File_content.count */
		if file_line_index == (total_object_num + 1) do
		(
			/* Generate the path to export file */
			model_path = testure_base_path + "Model_output\\" + "Model_Week_" + week_num_string + "\\" + "Model_Week_" + week_num_string
			
			/* Print the model path that the model is going to exported to */
			print model_path
			
			/* Export the current model to .obj with no prompt to the model path */
			exportfile (model_path + ".obj") #noprompt
			
			
			/* Save the .max file to the model path */
			/* "useNewfile: false" will change the current 3dMax project to the output project*/
			/* Cautious: this line can crash easily */
			saveMaxFile (model_path + ".max") useNewfile:false
			
		)
	)
)

/* Views: Viewport Materials Display as Shaded with Maps, to see the texture in 3dMax project */
actionMan.executeAction 0 "63545"

/*

*/
