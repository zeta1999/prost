#include "linop/linop_gradient.hpp"

#include <iostream>

template<typename T>
__global__
void LinOpGradient2DKernel(T *d_res,
                           T *d_rhs,
                           size_t nx,
                           size_t ny,
                           size_t L)
{
  size_t x = threadIdx.x + blockDim.x * blockIdx.x;
  size_t y_tilde = threadIdx.y + blockDim.y * blockIdx.y;
  size_t y = y_tilde % ny;
  size_t l = y_tilde / ny;

  if(x >= nx || y >= ny || l >= L)
    return;

  T gx, gy;
  size_t idx = y + x * ny + l * nx * ny;

  const T val_pt = d_rhs[idx];

  if(y < ny - 1)
    gy = d_rhs[idx + 1] - val_pt;
  else
    gy = static_cast<T>(0);
  
  if(x < nx - 1)
    gx = d_rhs[idx + ny] - val_pt;
  else
    gx = static_cast<T>(0);

  d_res[idx] += gx;
  d_res[idx + nx * ny * L] += gy;
}


template<typename T>
__global__
void LinOpDivergence2DKernel(T *d_res,
                             T *d_rhs,
                             size_t nx,
                             size_t ny,
                             size_t L)
{
  size_t x = threadIdx.x + blockDim.x * blockIdx.x;
  size_t y_tilde = threadIdx.y + blockDim.y * blockIdx.y;
  size_t y = y_tilde % ny;
  size_t l = y_tilde / ny;

  if(x >= nx || y >= ny || l >= L)
    return;

  T divx, divy;
  size_t idx = y + x * ny + l * nx * ny;

  if(y < ny - 1)
    divy = d_rhs[idx + nx * ny * L];
  else
    divy = 0;
  
  if(y > 0)
    divy -= d_rhs[idx + nx * ny * L - 1];

  if(x < nx - 1)
    divx = d_rhs[idx];
  else
    divx = 0;
  
  if(x > 0)
    divx -= d_rhs[idx - ny];
  
  d_res[idx] -= (divx + divy); // adjoint is minus the divergence
}

template<typename T>
__global__
void LinOpGradient3DKernel(T *d_res,
                           T *d_rhs,
                           size_t nx,
                           size_t ny,
                           size_t L)
{
  size_t x = threadIdx.x + blockDim.x * blockIdx.x;
  size_t y_tilde = threadIdx.y + blockDim.y * blockIdx.y;
  size_t y = y_tilde  % ny;
  size_t l = y_tilde / ny;

  if(x >= nx || y >= ny || l >= L)
    return;
  
  T gx, gy, gl;
  size_t idx = y + x * ny + l * nx * ny;

  const T val_pt = d_rhs[idx];
  
  if(y < ny - 1)
    gy = d_rhs[idx + 1] - val_pt;
  else
    gy = static_cast<T>(0);

  if(x < nx - 1)
    gx = d_rhs[idx + ny] - val_pt;
  else
    gx = static_cast<T>(0);

  if(l < L - 1)
    gl = d_rhs[idx + ny * nx] - val_pt;
  else
    gl = -val_pt; // dirichlet

  d_res[idx] += gx;
  d_res[idx + ny * nx * L] += gy;
  d_res[idx + 2 * ny * nx * L] += gl;
}


template<typename T>
__global__
void LinOpDivergence3DKernel(T *d_res,
                             T *d_rhs,
                             size_t nx,
                             size_t ny,
                             size_t L)
{
  size_t x = threadIdx.x + blockDim.x * blockIdx.x;
  size_t y_tilde = threadIdx.y + blockDim.y * blockIdx.y;
  size_t y = y_tilde  % ny;
  size_t l = y_tilde / ny;

  if(x >= nx || y >= ny || l >= L)
    return;
  
  T divx, divy, divl;
  size_t idx = y + x * ny + l * ny * nx;

  if(x < nx - 1)
    divx = d_rhs[idx];
  else
    divx = 0;

  if(y < ny - 1)
    divy = d_rhs[idx + nx * ny * L];
  else
    divy = 0;

  divl = d_rhs[idx + 2 * nx * ny * L];

  if(y > 0)
    divy -= d_rhs[idx + nx * ny * L - 1];

  if(x > 0)
    divx -= d_rhs[idx - ny];

  if(l > 0)
    divl -= d_rhs[idx + 2 * nx * ny * L - nx * ny];

  d_res[idx] -= (divx + divy + divl); // adjoint is minus the divergence
}

template<typename T>
__global__
void LinOpGradient2DKernelLabelFirst(
  T *d_res,
  T *d_rhs,
  size_t nx,
  size_t ny,
  size_t L)
{
  size_t x = threadIdx.x + blockDim.x * blockIdx.x;
  size_t y_tilde = threadIdx.y + blockDim.y * blockIdx.y;
  size_t y = y_tilde / L;
  size_t l = y_tilde % L;

  if(x >= nx || y >= ny || l >= L)
    return;

  T gx, gy;
  size_t idx = l + y * L + x * ny * L;

  const T val_pt = d_rhs[idx];

  if(y < ny - 1)
    gy = d_rhs[idx + L] - val_pt;
  else
    gy = static_cast<T>(0);
  
  if(x < nx - 1)
    gx = d_rhs[idx + ny * L] - val_pt;
  else
    gx = static_cast<T>(0);

  d_res[idx] += gx;
  d_res[idx + nx * ny * L] += gy;
}


template<typename T>
__global__
void LinOpDivergence2DKernelLabelFirst(
  T *d_res,
  T *d_rhs,
  size_t nx,
  size_t ny,
  size_t L)
{
  size_t x = threadIdx.x + blockDim.x * blockIdx.x;
  size_t y_tilde = threadIdx.y + blockDim.y * blockIdx.y;
  size_t y = y_tilde / L;
  size_t l = y_tilde % L;

  if(x >= nx || y >= ny || l >= L)
    return;

  T divx, divy;
  size_t idx = l + y * L + x * ny * L;

  if(y < ny - 1)
    divy = d_rhs[idx + nx * ny * L];
  else
    divy = 0;
  
  if(y > 0)
    divy -= d_rhs[idx + nx * ny * L - L];

  if(x < nx - 1)
    divx = d_rhs[idx];
  else
    divx = 0;
  
  if(x > 0)
    divx -= d_rhs[idx - ny * L];
  
  d_res[idx] -= (divx + divy); // adjoint is minus the divergence
}

template<typename T>
LinOpGradient2D<T>::LinOpGradient2D(
  size_t row, 
  size_t col, 
  size_t nx, 
  size_t ny, 
  size_t L, 
  bool label_first, 
  const std::vector<T>& m11, 
  const std::vector<T>& m12, 
  const std::vector<T>& m22)
  : LinOp<T>(row, col, nx*ny*L*2, nx*ny*L), 
    nx_(nx), ny_(ny), L_(L), d_m11_(0), d_m12_(0), d_m22_(0), label_first_(label_first)
{
}

template<typename T>
LinOpGradient2D<T>::~LinOpGradient2D() {
}

template<typename T>
void LinOpGradient2D<T>::EvalLocalAdd(T *d_res, T *d_rhs) {

  if(!label_first_) {
    dim3 block(1, 128, 1);
    dim3 grid((nx_ + block.x - 1) / block.x,
      (ny_*L_ + block.y - 1) / block.y,
      1);

    LinOpGradient2DKernel<<<grid, block>>>(d_res, d_rhs, nx_, ny_, L_);
  }
  else {
    dim3 block(1, 128, 1);
    dim3 grid((nx_ + block.x - 1) / block.x,
      (ny_*L_ + block.y - 1) / block.y,
      1);

    LinOpGradient2DKernelLabelFirst<<<grid, block>>>(d_res, d_rhs, nx_, ny_, L_);
  }
}

template<typename T>
void LinOpGradient2D<T>::EvalAdjointLocalAdd(T *d_res, T *d_rhs) {

  if(!label_first_) {
    dim3 block(2, 128, 1);
    dim3 grid((nx_ + block.x - 1) / block.x,
      (ny_*L_ + block.y - 1) / block.y,
      1);

    LinOpDivergence2DKernel<<<grid, block>>>(d_res, d_rhs, nx_, ny_, L_);
  }
  else {
    dim3 block(2, 128, 1);
    dim3 grid((nx_ + block.x - 1) / block.x,
      (ny_*L_ + block.y - 1) / block.y,
      1);

    LinOpDivergence2DKernelLabelFirst<<<grid, block>>>(d_res, d_rhs, nx_, ny_, L_);
  }
}

template<typename T>
T LinOpGradient2D<T>::row_sum(size_t row, T alpha) const { 
  return 2; 
}

template<typename T>
T LinOpGradient2D<T>::col_sum(size_t col, T alpha) const { 
  return 4; 
}

template<typename T>
LinOpGradient3D<T>::LinOpGradient3D(
  size_t row, size_t col, size_t nx, size_t ny, size_t L, 
  const std::vector<T>& m11, 
  const std::vector<T>& m12, 
  const std::vector<T>& m22)

  : LinOp<T>(row, col, nx*ny*L*3, nx*ny*L), nx_(nx), ny_(ny), L_(L), d_m11_(0), d_m12_(0), d_m22_(0)
{
}

template<typename T>
LinOpGradient3D<T>::~LinOpGradient3D() {
}

template<typename T>
void LinOpGradient3D<T>::EvalLocalAdd(T *d_res, T *d_rhs) {

  dim3 block(1, 128, 1);
  dim3 grid((nx_ + block.x - 1) / block.x,
            (ny_*L_ + block.y - 1) / block.y,
            1);

  LinOpGradient3DKernel<<<grid, block>>>(d_res, d_rhs, nx_, ny_, L_);
}

template<typename T>
void LinOpGradient3D<T>::EvalAdjointLocalAdd(T *d_res, T *d_rhs) {
  
  dim3 block(2, 128, 1);
  dim3 grid((nx_ + block.x - 1) / block.x,
            (ny_*L_ + block.y - 1) / block.y,
            1);

  LinOpDivergence3DKernel<<<grid, block>>>(d_res, d_rhs, nx_, ny_, L_);
}

template<typename T>
T LinOpGradient3D<T>::row_sum(size_t row, T alpha) const { 
  return 2; 
}

template<typename T>
T LinOpGradient3D<T>::col_sum(size_t col, T alpha) const { 
  return 6; 
}

template class LinOpGradient2D<float>;
template class LinOpGradient2D<double>;
template class LinOpGradient3D<float>;
template class LinOpGradient3D<double>;
