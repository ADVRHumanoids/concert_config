FROM hhcmhub/xbot2-noble-rt

# add robot config to bashrc
RUN echo 'source ~/xbot2_ws/src/concert_config/$CONFIG_PATH_DOCKER' >> ~/.bashrc

# concert specific packages
RUN cd xbot2_ws && \
    sudo chown user src && \
    cd recipes/multidof_recipes && git pull origin ros2
