# installation
Building for:
- Jetson Nano
- L4T 32.7.1/JetPack 4.6.1 
- Python 3.6
- PyTorch 1.10.0 (with CUDA)
- Tensorflow 2.7.0 (with CUDA)
- OpenCV 4.5.5 (with CUDA)

Build with:
```bash
$ sudo docker build -t <name> ./
```

Run with:
```bash
$ sudo docker run --runtime=nvidia -it <name>
```

# Reference
[https://github.com/dusty-nv/jetson-containers](https://github.com/dusty-nv/jetson-containers)
[https://github.com/JetsonHacksNano/buildOpenCV](https://github.com/JetsonHacksNano/buildOpenCV)
