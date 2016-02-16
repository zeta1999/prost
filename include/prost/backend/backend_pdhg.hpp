#ifndef PROST_BACKEND_PDHG_HPP_
#define PROST_BACKEND_PDHG_HPP_

#include <thrust/device_vector.h>

#include "prost/backend/backend.hpp"
#include "prost/common.hpp"

namespace prost {

template<typename T> class Prox;

///
/// \brief Implementation of the primal-dual hybrid-gradient method.
/// 
template<typename T> 
class BackendPDHG : public Backend<T> 
{
public:
  /// \brief Step size scheme for the PDHG.
  enum StepsizeVariant 
  {
    /// \brief Constant steps.
    kPDHGStepsAlg1 = 1,

    /// \brief Variable steps for strongly convex problems.
    kPDHGStepsAlg2,

    /// \brief Residual balancing scheme from "Goldstein, Esser" paper.
    kPDHGStepsResidualGoldstein,

    /// \brief Residual converging scheme from "Fougner, Boyd" paper
    kPDHGStepsResidualBoyd,
  };

  /// \brief Detailed options for the primal-dual algorithm.
  struct Options 
  {
    /// \brief Initial primal step size.
    double tau0;
  
    /// \brief Initial dual step size.
    double sigma0; 

    /// \brief Every how many iterations to compute the residuals?
    int residual_iter;

    /// \brief Scale step sizes to ensure tau*sigma*||K||^2 = 1. 
    bool scale_steps_operator;

    /// \brief Strong convexity parameter for algorithm 2 step size scheme.
    T alg2_gamma;

    /// \brief Parameters for residual balancing step size scheme.
    T arg_alpha0, arg_nu, arg_delta;

    /// \brief Parameters for residual converging step size scheme.
    T arb_delta, arb_tau;

    /// \brief Type of step-size scheme.
    typename BackendPDHG<T>::StepsizeVariant stepsize_variant;
  };

  BackendPDHG(const typename BackendPDHG<T>::Options& opts);
  virtual ~BackendPDHG();

  virtual void Initialize();
  virtual void PerformIteration();
  virtual void Release();

  virtual void current_solution(vector<T>& primal, vector<T>& dual) const;

  /// \brief Returns amount of gpu memory required in bytes.
  virtual size_t gpu_mem_amount() const;

private:
  void UpdateResidualsAndStepsizes();
  
private:
  // \brief Primal variable x^k.
  thrust::device_vector<T> x_; 

  // \brief Dual variables y^k.
  thrust::device_vector<T> y_; 

  // previous primal variable x^{k-1}
  thrust::device_vector<T> x_prev_; 

  // previous dual variable y^{k-1}
  thrust::device_vector<T> y_prev_; 

  // temporary variable to store result of proxs and residuals
  thrust::device_vector<T> temp_;

  // holds mat-vec product K x^k
  thrust::device_vector<T> kx_;

  // holds mat-vec product K^T y^k
  thrust::device_vector<T> kty_;

  // holds mat-vec product K x^{k-1}
  thrust::device_vector<T> kx_prev_;

  // holds mat-vec product K^T y^{k-1}
  thrust::device_vector<T> kty_prev_; 

  /// \brief Current primal step size.
  T tau_;

  /// \brief Current dual step size.
  T sigma_;

  /// \brief Current overrelaxation parameter.
  T theta_;

  /// \brief PDHG-specific options.
  typename BackendPDHG<T>::Options opts_;

  /// \brief Internal iteration counter.
  size_t iteration_;

  /// \brief For adaptive step size rule from Boyd's paper
  int arb_l_, arb_u_;

  /// \brief For adaptive step size rule from Goldstein's paper
  T arg_alpha_;

  /// \brief Internal prox_g
  vector< shared_ptr<Prox<T> > > prox_g_;

  /// \brief Internal prox_fstar
  vector< shared_ptr<Prox<T> > > prox_fstar_;
};

} // namespace prost

#endif // PROST_BACKEND_PDHG_HPP_