ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

USER root

# ffmpeg for matplotlib anim
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    rm -rf /var/lib/apt/lists/*

USER $NB_UID

# Install Python packages
RUN conda install --quiet --yes \
    'conda-forge::blas=*=openblas' \
    'ipywidgets=7.5*' \
    'pandas=0.24*' \
    'numexpr=2.6*' \
    'matplotlib=3.0*' \
    'scipy=1.2*' \
    'seaborn=0.9*' \
    'scikit-learn=0.20*' \
    'scikit-image=0.14*' \
    'tensorflow=1.13*' \
    'keras=2.2*' \
    'sympy=1.3*' \
    'cython=0.29*' \
    'patsy=0.5*' \
    'statsmodels=0.9*' \
    'cloudpickle=0.8*' \
    'dill=0.2*' \
    'dask=1.1.*' \
    'numba=0.42*' \
    'bokeh=1.0*' \
    'sqlalchemy=1.3*' \
    'hdf5=1.10*' \
    'h5py=2.9*' \
    'vincent=0.4.*' \
    'beautifulsoup4=4.7.*' \
    'protobuf=3.7.*' \
    'xlrd'  && \
    conda clean --all -f -y && \
    # Activate ipywidgets extension in the environment that runs the notebook server
    jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
    # Also activate ipywidgets extension for JupyterLab
    # Check this URL for most recent compatibilities
    # https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
    jupyter labextension install @jupyter-widgets/jupyterlab-manager@^1.0.0 && \
    jupyter labextension install jupyterlab_bokeh@1.0.0 && \
    npm cache clean --force && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    rm -rf /home/$NB_USER/.node-gyp && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install facets which does not have a pip or conda package at the moment
RUN cd /tmp && \
    git clone https://github.com/PAIR-code/facets.git && \
    cd facets && \
    jupyter nbextension install facets-dist/ --sys-prefix && \
    cd && \
    rm -rf /tmp/facets && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions /home/$NB_USER


USER root

# Install Julia & Julia packages
# Packages are installed in /opt/julia instead of $HOME
ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=1.1.0

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    echo "80cfd013e526b5145ec3254920afd89bb459f1db7a2a3f21849125af20c05471 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

# Show Julia where conda libraries are
RUN mkdir /etc/julia && \
    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
    mkdir $JULIA_PKGDIR && \
    chown $NB_USER $JULIA_PKGDIR && \
    fix-permissions $JULIA_PKGDIR

USER $NB_UID

# Add Julia packages
RUN julia -e 'using Pkg; Pkg.update()' && \
    julia -e "using Pkg; pkg\"add CSV DataFrames Flux IJulia Images InstantiateFromURL JLD Printf Plots PyPlot RDatasets ScikitLearn StatsBase\"; pkg\"precompile\"" && \
    mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
    rm -rf $HOME/.local && \
    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter
