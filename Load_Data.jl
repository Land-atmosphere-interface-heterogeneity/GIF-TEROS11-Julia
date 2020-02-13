# Load Packages
using CSV, DataFrames, Dates, Statistics
# Set working directory
cd("C:\\Users\\arenchon\\Documents\\GitHub\\GIF-TEROS11-Julia")
# Load data from TEROS input files
Input_FN = readdir("Input\\TEROS\\")
permute!(Input_FN,[3,4,5,6,7,8,9,10,11,1,2]) # need to reorder from 1 to 11
n = length(Input_FN) # this is the number of input files, useful later
data = DataFrame[]
[push!(data, CSV.read(string("Input\\TEROS\\",Input_FN[i]),dateformat="yyyy-mm-dd HH:MM:SS+00:00")) for i in 1:n]
# Download met data
download("http://www.atmos.anl.gov/ANLMET/numeric/2019/nov19met.data", "Input\\MET TOWER\\nov19met.data")
download("http://www.atmos.anl.gov/ANLMET/numeric/2019/dec19met.data", "Input\\MET TOWER\\dec19met.data")
# Load that met data
col_name = [:DOM,:Month,:Year,:Time,:PSC,:WD60,:WS60,:WD_STD60,:T60,:WD10,:WS10,:WD_STD10,:T10,:DPT,:RH,:TD100,:Precip,:RS,:RN,:Pressure,:WatVapPress,:TS10,:TS100,:TS10F]
metdata = CSV.read(met_path, delim=' ',header=col_name,ignorerepeated=true,datarow=1,footerskip=2)
metdata2 = CSV.read(met_path2, delim=' ',header=col_name,ignorerepeated=true,datarow=1,footerskip=2)
metdata = vcat(metdata,metdata2)
met_n = size(metdata,1)

