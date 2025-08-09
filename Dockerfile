FROM bash
RUN apt update && apt install -y jq bash-builtins
COPY . /opt/app
WORKDIR /opt/app
RUN useradd -m appuser
USER appuser
CMD ["examples/rest.bash"]
