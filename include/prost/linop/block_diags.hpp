#ifndef PROST_BLOCK_DIAGS_HPP_
#define PROST_BLOCK_DIAGS_HPP_

#include "prost/linop/block.hpp"

namespace prost {

///
/// \brief Linear operator implementation of the MATLAB command speye.
///
/// \param ndiags: number of diagonals
/// \param offsets: array of size ndiags, starting position of diagonals
/// \param factors: array of size ndiags, constant factor each diagonal
///                 is multiplied with

template<typename T>
class BlockDiags : public Block<T> {
public:
  BlockDiags(size_t row,
	     size_t col,
	     size_t nrows,
	     size_t ncols,
	     size_t ndiags,
	     const std::vector<ssize_t>& offsets,
	     const std::vector<T>& factors);
  
  virtual ~BlockDiags() {}

  virtual void Initialize();

  virtual size_t gpu_mem_amount() const { return 0; }
  virtual T row_sum(size_t row, T alpha) const;
  virtual T col_sum(size_t col, T alpha) const;

  /// \brief Important: has to be called once during initializaiton.
  static void ResetConstMem() { cmem_counter_ = 0; }

protected:
  virtual void EvalLocalAdd(
    const typename device_vector<T>::iterator& res_begin,
    const typename device_vector<T>::iterator& res_end,
    const typename device_vector<T>::const_iterator& rhs_begin,
    const typename device_vector<T>::const_iterator& rhs_end);

  virtual void EvalAdjointLocalAdd(
    const typename device_vector<T>::iterator& res_begin,
    const typename device_vector<T>::iterator& res_end,
    const typename device_vector<T>::const_iterator& rhs_begin,
    const typename device_vector<T>::const_iterator& rhs_end);

  /// \brief Start index in constant memory.
  size_t cmem_offset_;

  /// \brief Number of diagonals.
  size_t ndiags_;

  /// \brief Diagonal offsets.
  std::vector<ssize_t> offsets_;

  /// \brief Diagonal factors.
  std::vector<float> factors_;

  /// \brief Allows to handle several BlockDiags.
  static size_t cmem_counter_;
};

}

#endif // PROST_BLOCK_DIAGS_HPP_
