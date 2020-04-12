//Get input and output directories
dir = getDirectory('Input directory ');
dir_out = getDirectory('Output directory ');
//Get list of files in the input folder
list = getFileList(dir);


//Create file where results are stored
f=File.open(dir_out+"results.txt");


//Setup the measurements we want (actually we only want the area fraction, but the other ones are default.. can be erased!
run("Set Measurements...", "area mean standard min shape area_fraction display redirect=None decimal=3");
setBatchMode(true);


for (i=0;i<list.length;i++){
	if(File.isDirectory(dir+list[i])){ //File is a directory (subfolder), therefore process!
	dir_temp=dir+list[i];
	list_temp=getFileList(dir_temp);
	processFolder(dir_temp,list_temp,f);	
	}
	
}

//Finish macro
setBatchMode(false);
File.close(f);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Processing function for subfolder, or folders
function processFolder(dir,list,f){
	//Initialize output
	A_frac=newArray(list.length);
	//Get name of folder (not whole path)
	f_name=File.getName(dir);
	//Print the first line as the input directory
	print(f,"Results of files in folder "+f_name);
	//Loop
	for (i=0; i<list.length; i++) {
	//Process image and assign to array
    A_frac[i]=processArea(dir,list[i],s_blur);
    //Print result of current image (plus its name)
    print(f,list[i]+"	"+A_frac[i]);
    
       
	} 

	//Print average
	Array.getStatistics(A_frac,min,max,mean,std);
	print(f,"Average of images in folder	"+mean);
	
}




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Processing function: Thresold, adaptive threshold, analize particles (to eliminate small objects), get area fraction and export it (as output)
function processArea(input,nameImr){
	open(input+nameIm);
	selectWindow(nameIm);
	run("8-bit");
	run("Gaussian Blur...", "sigma=1"r);

	//Duplicate and threshold (remove obvious background)
	run("Duplicate...", "title=Copy");
	selectWindow("Copy");
	setThreshold(60, 255);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	
	//Apply mask
	imageCalculator("AND create", nameIm,"Copy");

	//Select partially thresholded image and appply local threshold
	selectWindow("Result of "+nameIm);
	run("Auto Local Threshold", "method=Mean radius=30 parameter_1=-1 parameter_2=0 white");
	run("Analyze Particles...", "size=0-20 show=Masks clear");
	imageCalculator("XOR create", "Result of "+nameIm,"Mask of Result of "+nameIm);
	selectWindow("Result of Result of "+nameIm);
	//Measure and set area fraction as output
	run("Measure");
	A_frac=getResult("%Area");
	//Close results
	selectWindow("Results");
    run("Close");
    //Close all images
    run("Close All");
	return A_frac;
	
}