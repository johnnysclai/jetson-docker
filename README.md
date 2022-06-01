# installation
Building for:
- Jetson Nano
- L4T 32.7.1/JetPack 4.6.1 
- Python 3.6
- PyTorch 1.10.0 (with CUDA)
- Tensorflow 2.7.0 (with CUDA)
- OpenCV 4.5.5 (with CUDA)

Build it with:
```bash
$ sudo docker build -t <name> ./
```

Run it with:
```bash
$ sudo docker run --runtime=nvidia -it <name>
```

# Reference
1. [https://github.com/dusty-nv/jetson-containers](https://github.com/dusty-nv/jetson-containers)
2. [https://github.com/JetsonHacksNano/buildOpenCV](https://github.com/JetsonHacksNano/buildOpenCV)
