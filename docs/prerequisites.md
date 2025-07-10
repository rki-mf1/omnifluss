# Prerequisites

Omnifluss is developed using the Nextflow workflow language and intended for Unix operating systems.
You can find successfully tested work environments and operating systems below.

## User requirements

**Operating system:** Ubuntu Linux 24.04.02 LTS, 22.04.05 LTS <br>
**Work environment:** nextflow 25.04.3 <br>
**Package manager/ container engine**: at least one of conda, singularity or docker. We strongly recommend using singularity or docker.

If you are using omnifluss with your data then these user requirements suffice.
You can install Nextflow via its [official installation instructions](https://nextflow.io/docs/latest/install.html) or simply via `conda`:

```bash
conda create -n omnifluss -c bioconda -c conda-forge nextflow==25.04.3
```

> ***Note:***
> With Nextflow in your active working environment you don't need to install omnifluss at all!
> In the standard use case, Nextflow will automatically clone and use the code from the Github repository.

## Developer requirements

**Operating system:** Ubuntu Linux 24.04.02 LTS, 22.04.05 LTS <br>
**Work environment:** nextflow 25.04.3, nf-core 3.3.1, nf-test 0.9.2 <br>
**Package manager/ container engine**: conda and at least one of singularity or docker.

These requirements are only for the developers and people intending to contribute to omnifluss.
You can recreate our developers' work environment via conda `conda`:

```bash
conda create -n omnifluss -c bioconda -c conda-forge \
    nextflow==25.04.3 \
    nf-core==3.3.1 \
    nf-test==0.9.2
```
