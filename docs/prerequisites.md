# Prerequisites

Omnifluss is developed using the Nextflow workflow language and intended for Unix operating systems.
You can find successfully tested work environments and operating systems below.

**Operating system:** Ubuntu Linux 24.04.02 LTS, 22.04.05 LTS <br>
**Work environment:** nextflow 25.04.3, nf-core 3.3.1, nf-test 0.9.2

You can recreate our developer's work environment using the `conda` package manager via:
```bash
conda create -n omnifluss -c bioconda -c conda-forge \
    nextflow==25.04.3 \
    nf-core==3.3.1 \
    nf-test==0.9.2
```

> ***Note:***
> With Nextflow in your active working environment you don't need to install omnifluss at all!
> In the standard use case, Nextflow will automatically clone and use the code from the Github repository.
