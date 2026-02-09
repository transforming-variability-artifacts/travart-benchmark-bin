# Benchmarking artifacts and auxiliary scripts

[![DOI](https://zenodo.org/badge/1056526048.svg)](https://doi.org/10.5281/zenodo.18507632)

The tarballs contain the benchmarking results presented in the thesis. The *_new tarball contains the effective observations, the tarball with the older iteration of the results
are used by the `travart-control.R` script (see `Rscripts` folder), this tarball also contains some of the early analysis done with JASP, which was cut in the final version of the thesis.

Both tarballs should be extracted. If no changes are done to the folder structure (and if you extract the tarballs into the repository root), provided R scripts can be used without adapting the paths in said scripts.
We suggest using R Studio to interactively run the provided scripts. A convenience script `benchmark.sh` is provided for benchmarking further artifact datasets. This script goes through all 9 different transformation
paths investigated in scope of the thesis, repeating each transformation 8 times. The first 3 iterations can be discarded if no previous transformations were done and TraVarT was cold-started. Once benchmarking
data is acquired, you can use the auxilliary Python scripts also provided in this repository. These expect to the run from the root folder where the benchmarking results are stored in subfolders (see `file_paths` variable
in, ex., `take_average_merge-by-path.py`).

Datasets used for benchmarking (for results provided in tarball):

- CDL from UVLHub: https://zenodo.org/records/12697319
- SPLOT from UVLHub: https://zenodo.org/records/12697473
- uClibc, BusyBox, Linux and CVE collected from: https://zenodo.org/records/11652925
- Native Kconfig models and native DOPLER models available in respective TraVarT plugin repositories
