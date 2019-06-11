# This script will process files using FLIP2PDF
# Arguments:
#	FLIP2PDF executable directory
#	input file directory - Point this script at the test file directory, not a specific file
#	output file directory - If it doesn't exist it will be created. If it does exist, it will be cleaned.
#							When cleaning, script makes sure there are ONLY pdfs in output-directory, so input-file-directory isn't accidently deleted

function Run-Test($testFile, $testProfile) {
	Write-Output "Running $testFile with $testProfile.json"
	&$cmdExe --input "$(Join-Path $inDir $testFile)" --output "$(Join-Path $outDir $testFile-$testProfile).pdf" --profile "$(Join-Path $inDir 'test_profiles' $testProfile).json" # | Out-Null
}

function Display-Help() {
	Write-Output "	This script will execute pdf output tests using flip2pdf

	This script requires PowerShell Core 6

	Usage: $(split-path $MyInvocation.PSCommandPath -Leaf) <FLIP2PDF-installation-directory> <input-file-directory> <output-directory>

	Arguments:
		FLIP2PDF installation directory
		input file directory: where the test files and profiles are
		output directory: where output should go"
}

function Display-Usage() {
	Write-Output "Usage: $(split-path $MyInvocation.PSCommandPath -Leaf) <FLIP2PDF-installation-directory> <input-file-directory> <output-directory>
Use -help for info, e.g.: $(split-path $MyInvocation.PSCommandPath -Leaf) -help"
}

# Check correct number of args
if (($args.length -eq 1) -and ($args[0] -eq "-help")) {
	Display-Help
	Exit
}
if ($args.length -ne 3) {
	Display-Usage
	Exit
}

if ($IsLinux) {
	$cmdExe=Join-Path $args[0] "FLIP2PDF"
	Write-Output "Linux detected"
}
ElseIf ($IsWindows) {
	$cmdExe=Join-Path $args[0] "FLIP2PDF.exe"
	Write-Output "Windows detected"
}
else {
	Write-Output "Unsupported OS detected"
	Exit
}

$inDir="$($args[1])"
$outDir="$($args[2])"
Write-Output "Starting FLIP2PDF Test..."
Write-Output "	FLIP2PDF path:              $cmdExe"
Write-Output "	Input directory:            $inDir"
Write-Output "	Output directory:           $outDir"

# Check installation directory
if (!(Test-Path -Path $cmdExe -PathType leaf)) {
	Write-Output "Cannot find flip2pdf at $cmdExe"
	Exit
}

# If output directory doesn't exist, create it. If it does exist, clean it
if(!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
	Write-Output "Output directory created at: $outDir"
}
else {
	Write-Output "Output directory found."
	# Check if directory has any files besides pdfs
	if ((Get-ChildItem -Path $outDir -Recurse -Exclude *.pdf).count -gt 0){
		Write-Output "Non-PDF files found in output-directory. Are you sure that this isn't the input-file-directory?"
		Exit
	}
	else {
		Write-Output "No non-PDF files found in output-directory. Cleaning output-directory"
		Get-ChildItem -Path $outDir -Recurse | Remove-Item -Recurse
	}
}

# Check input directory exists
if (!(Test-Path -Path $inDir -PathType Container)) {
	Write-Output "Cannot find input file directory at $inDir"
	Exit
}
else {
	# Check that input directory has non-pdf files somewhere
	if ((Get-ChildItem -Path $inDir -Recurse -Exclude *.pdf).count -gt 0){
		Write-Output "Non-PDF files located at input directory"
		if ((Get-ChildItem -Path $inDir -Recurse -Filter *.pdf).count -gt 0){
			Write-Output "Warning: PDF files found at input directory"
			Exit
		}
	}
	else {
		Write-Output "No non-PDF files found at input directory"
		Exit
	}
}

# Test files to run with standard json file
$standardJsonList=@("ducky.bmp",
				"ducky.jpg",
				"ducky.png",
				"ducky.tif",
				"excelxls.xls",
				"excelxlsx.xlsx",
				"test.ps",
				"sample.ps",
				"sample.eps",
				"powerpointppt.ppt",
				"powerpointpptx.pptx",
				"worddocstandard.doc",
				"worddocx.docx")
foreach ($file in $standardJsonList) {
	Run-Test $file standard
}

# Run files with specific json profile
Run-Test worddocImageFlate.doc standardReversedFlateJpeg
Run-Test sample.ps standardReversedFlateJpeg
Run-Test sample.ps psToPdfx3Flate
Run-Test sample.ps psToPdfx3Jpeg
Run-Test worddocImageFlate.doc docToPdfaFlate
Run-Test worddocImageJpeg.doc docToPdfaJpeg



