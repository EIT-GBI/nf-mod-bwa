FROM mambaorg/micromamba:1.5.8

USER root

RUN micromamba install -y -n base -c bioconda -c conda-forge \
        bwa=0.7.18 \
        samtools \
    && micromamba clean --all --yes

ENV PATH=/opt/conda/bin:$PATH
 
CMD ["bwa"]
