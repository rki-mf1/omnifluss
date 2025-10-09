# Prerequisites

Omnifluss is developed and launched using the Nextflow workflow language and intended for Unix operating systems.

## User requirements

We successfully tested the following work environments and operating systems to launch omnifluss:

**Operating system:** Ubuntu Linux 24.04.02 LTS; 22.04.05 LTS <br>
**Package manager/ container engine**: conda, singularity or docker. We strongly recommend the container engines (singularity or docker) for stability. <br>
**Work environment:** nextflow 25.04.3

These requirements suffice for running omnifluss on your data.
You can install Nextflow via its [official installation instructions](https://nextflow.io/docs/latest/install.html) or simply via `conda`:

```bash
conda create -n omnifluss -c bioconda -c conda-forge nextflow==25.04.3
```

> ***Note:***
> With Nextflow in your active working environment you don't need to install omnifluss at all!
> In the standard use case, Nextflow will automatically clone and use the omnifluss source code from its Github repository.

## Developer requirements

**Operating system:** Ubuntu Linux 24.04.02 LTS, 22.04.05 LTS <br>
**Package manager/ container engine**: conda, singularity or docker. We strongly recommend the container engines (singularity or docker) for stability. <br>
**Work environment:** nextflow 25.04.3, nf-core 3.3.1, nf-test 0.9.2

These requirements are only for developers and people intending to contribute to omnifluss.
You can recreate our developers' work environment via conda `conda`:

```bash
conda create -n omnifluss -c bioconda -c conda-forge \
    nextflow==25.04.3 \
    nf-core==3.3.1 \
    nf-test==0.9.2
```
