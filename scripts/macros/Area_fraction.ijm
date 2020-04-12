dir = getDirectory('Choose Directory ');
dir_out = getDirectory('Choose Directory for Results ');
list = getFileList(dir);

setBatchMode(true);
//Setup the measurements we want (actually we only want the area fraction, but the other ones are default.. can be erased!
run("Set Measurements...", "area mean standard min shape area_fraction display redirect=None decimal=3");
//Initialize output
A_frac_out=newArray(list.length);


//Create file where results are stored
f_name=File.getName(dir);
f=File.open(dir_out+f_name+"-res.txt");
//Print the first line as the input directory
print(f,f_name);


//Loop for image stack
for (i=0; i<list.length; i++) {
	//Process image and assign to array
    A_frac_out[i]=processArea(dir,list[i],Ra,Tr);
    //Print
    //print(f,list[i]+"	"+A_frac_out[i]);
          
} 

//Print average
Array.getStatistics(A_frac_out,min,max,mean,std);
print(f,"Average of images in folder	"+mean);
print(f,"Std dev coverage of images in folder	"+std);
print(f,"Min coverage of images in folder	"+min);
print(f,"Max coverage of images in folder	"+max);


setBatchMode(false);
File.close(f);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Processing function: Thresold, adaptive threshold, analize particles (to eliminate small objects), get area fraction and export it (as output)
function processArea(input,nameIm,R,T){
	open(input+nameIm);
	selectWindow(nameIm);
	run("8-bit");
	run("Gaussian Blur...", "sigma=1");

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