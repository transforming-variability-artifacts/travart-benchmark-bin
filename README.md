# Benchmarking artifacts and auxiliary scripts

The tarballs contain the benchmarking results presented in the thesis. The *_new tarball contains the effective observations, the tarball with the older iteration of the results
are used by the `travart-control.R` script (see `Rscripts` folder), this tarball also contains some of the early analysis done with JASP, which was cut in the final version of the thesis.
Almost all helper scripts have absolute paths that need to be adapted according to the own directory structure.

Datasets used for benchmarking:

- CDL from UVLHub: https://zenodo.org/records/12697319
- SPLOT from UVLHub: https://zenodo.org/records/12697473
- uClibc, BusyBox, Linux and CVE collected from: https://zenodo.org/records/11652925
- Native Kconfig models and native DOPLER models available in respective TraVarT plugin repositories
