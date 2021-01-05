FROM amphaal/base-docker-ci:latest
LABEL maintainer="guillaume.vara@gmail.com"

USER root
    #add multilib mirrorlist (for wine)
    RUN echo "[multilib]" >> /etc/pacman.conf \
        && echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf \
        && echo "" >> /etc/pacman.conf
    
    #add msys and mingw64 mirrorlist
    RUN echo "[mingw64]" >> /etc/pacman.conf \
        && echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf \
        && echo "Include = /etc/pacman.d/mirrorlist.mingw64" >> /etc/pacman.conf \
        && echo "" >> /etc/pacman.conf \
        && echo "[msys]" >> /etc/pacman.conf \
        && echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf \
        && echo "Include = /etc/pacman.d/mirrorlist.msys" >> /etc/pacman.conf \
        && echo "" >> /etc/pacman.conf
        
    #copy mirrorlists
    ADD https://raw.githubusercontent.com/msys2/MSYS2-packages/master/pacman-mirrors/mirrorlist.mingw64 /etc/pacman.d/
    ADD https://raw.githubusercontent.com/msys2/MSYS2-packages/master/pacman-mirrors/mirrorlist.msys /etc/pacman.d/
    
    # update mirrorlist
    RUN pacman -Syyu --needed --noconfirm
    
    #install wine
    RUN pacman -S --noconfirm --noprogressbar --needed wine
    
    # setup wine
    ENV WINEDEBUG=fixme-all
    ENV WINEARCH=win64
    ENV WINEPATH=/mingw64/bin
    RUN winecfg

USER devel
    RUN winecfg

USER root
    RUN pacman -S --needed --noconfirm mingw64/mingw-w64-x86_64-crt
    RUN pacman -S --needed --noconfirm mingw64/mingw-w64-x86_64-gcc
    RUN pacman -S --needed --noconfirm mingw64/mingw-w64-x86_64-binutils

    RUN pacman -S --needed --noconfirm mingw64/mingw-w64-x86_64-qt-installer-framework
    
    # generate wrapper
    COPY wine-wrappers /wine-wrappers
    RUN cd wine-wrappers && cmake -GNinja -B_gen -H. && ninja -C_gen install && cd ..

    CMD [ "/usr/bin/bash" ]
