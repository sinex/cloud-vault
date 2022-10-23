FROM replicated/dockerfilelint:f7bdc89 AS base
COPY entrypoint.sh /
RUN ln -sv /dockerfilelint/bin/dockerfilelint /bin/dockerfilelint
WORKDIR /workspace
ENTRYPOINT []
CMD "/entrypoint.sh"
