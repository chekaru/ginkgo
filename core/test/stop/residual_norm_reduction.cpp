/*******************************<GINKGO LICENSE>******************************
Copyright 2017-2018

Karlsruhe Institute of Technology
Universitat Jaume I
University of Tennessee

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
******************************<GINKGO LICENSE>*******************************/

#include <core/stop/residual_norm_reduction.hpp>


#include <gtest/gtest.h>


namespace {


constexpr double reduction_factor = 1.0e-16;


class ResidualNormReduction : public ::testing::Test {
protected:
    ResidualNormReduction()
    {
        exec_ = gko::ReferenceExecutor::create();
        factory_ = gko::stop::ResidualNormReduction<>::Factory::create()
                       .with_reduction_factor(reduction_factor)
                       .on_executor(exec_);
    }

    std::unique_ptr<gko::stop::ResidualNormReduction<>::Factory> factory_;
    std::shared_ptr<const gko::Executor> exec_;
};


TEST_F(ResidualNormReduction, CanCreateFactory)
{
    ASSERT_NE(factory_, nullptr);
    ASSERT_EQ(factory_->get_parameters().reduction_factor, reduction_factor);
    ASSERT_EQ(factory_->get_executor(), exec_);
}

TEST_F(ResidualNormReduction, CannotCreateCriterionWithoutB)
{
    ASSERT_THROW(factory_->generate(nullptr, nullptr, nullptr, nullptr),
                 gko::NotSupported);
}

TEST_F(ResidualNormReduction, CanCreateCriterionWithB)
{
    std::shared_ptr<gko::LinOp> scalar =
        gko::initialize<gko::matrix::Dense<>>({1.0}, exec_);
    auto criterion =
        factory_->generate(nullptr, nullptr, nullptr, scalar.get());
    ASSERT_NE(criterion, nullptr);
}


}  // namespace