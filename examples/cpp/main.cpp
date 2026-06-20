/**
 * C++ example - Math library with templates and modern C++
 */
#include <algorithm>
#include <concepts>
#include <cmath>
#include <exception>
#include <iostream>
#include <memory>
#include <numeric>
#include <optional>
#include <ranges>
#include <string>
#include <vector>

namespace devmedia::math {

// ---------- Concepts ----------

template <typename T>
concept Numeric = std::is_arithmetic_v<T>;

template <typename T>
concept FloatingPoint = std::is_floating_point_v<T>;

// ---------- Math Constants ----------

template <FloatingPoint T = double>
struct Constants {
    static constexpr T pi = T(3.14159265358979323846);
    static constexpr T e = T(2.71828182845904523536);
    static constexpr T phi = T(1.61803398874989484820);
    static constexpr T sqrt2 = T(1.41421356237309504880);
};

// ---------- Vector ----------

template <Numeric T, size_t N>
class Vector {
private:
    std::array<T, N> data_{};

public:
    Vector() = default;

    Vector(std::initializer_list<T> list) {
        std::ranges::copy(list, data_.begin());
    }

    T& operator[](size_t index) { return data_[index]; }
    const T& operator[](size_t index) const { return data_[index]; }

    constexpr size_t size() const { return N; }

    // Norm (magnitude)
    double magnitude() const requires FloatingPoint<T> {
        double sum = 0.0;
        for (const auto& v : data_) {
            sum += static_cast<double>(v) * static_cast<double>(v);
        }
        return std::sqrt(sum);
    }

    // Dot product
    T dot(const Vector& other) const {
        T result{};
        for (size_t i = 0; i < N; ++i) {
            result += data_[i] * other.data_[i];
        }
        return result;
    }

    Vector operator+(const Vector& other) const {
        Vector result;
        for (size_t i = 0; i < N; ++i) {
            result.data_[i] = data_[i] + other.data_[i];
        }
        return result;
    }

    Vector operator*(T scalar) const {
        Vector result;
        for (size_t i = 0; i < N; ++i) {
            result.data_[i] = data_[i] * scalar;
        }
        return result;
    }
};

template <Numeric T, size_t N>
std::ostream& operator<<(std::ostream& os, const Vector<T, N>& v) {
    os << "(";
    for (size_t i = 0; i < N; ++i) {
        if (i > 0) os << ", ";
        os << v[i];
    }
    os << ")";
    return os;
}

// ---------- Matrix ----------

template <Numeric T, size_t Rows, size_t Cols>
class Matrix {
private:
    std::array<std::array<T, Cols>, Rows> data_{};

public:
    Matrix() = default;

    std::array<T, Cols>& operator[](size_t row) { return data_[row]; }
    const std::array<T, Cols>& operator[](size_t row) const { return data_[row]; }

    constexpr size_t rows() const { return Rows; }
    constexpr size_t cols() const { return Cols; }

    // Identity matrix
    static Matrix identity() requires (Rows == Cols) {
        Matrix m;
        for (size_t i = 0; i < Rows; ++i) {
            m[i][i] = T(1);
        }
        return m;
    }

    // Matrix multiplication
    template <size_t OtherCols>
    Matrix<T, Rows, OtherCols> operator*(const Matrix<T, Cols, OtherCols>& other) const {
        Matrix<T, Rows, OtherCols> result;
        for (size_t i = 0; i < Rows; ++i) {
            for (size_t j = 0; j < OtherCols; ++j) {
                for (size_t k = 0; k < Cols; ++k) {
                    result[i][j] += data_[i][k] * other[k][j];
                }
            }
        }
        return result;
    }

    // Transpose
    Matrix<T, Cols, Rows> transpose() const {
        Matrix<T, Cols, Rows> result;
        for (size_t i = 0; i < Rows; ++i) {
            for (size_t j = 0; j < Cols; ++j) {
                result[j][i] = data_[i][j];
            }
        }
        return result;
    }
};

// ---------- Statistics ----------

template <Numeric T>
class Statistics {
public:
    static double mean(const std::vector<T>& data) {
        if (data.empty()) {
            throw std::invalid_argument("Data cannot be empty");
        }
        return std::accumulate(data.begin(), data.end(), 0.0) / data.size();
    }

    static double median(std::vector<T> data) {
        if (data.empty()) {
            throw std::invalid_argument("Data cannot be empty");
        }
        std::ranges::sort(data);
        size_t n = data.size();
        if (n % 2 == 0) {
            return (data[n / 2 - 1] + data[n / 2]) / 2.0;
        }
        return static_cast<double>(data[n / 2]);
    }

    static double stddev(const std::vector<T>& data) {
        if (data.size() < 2) {
            throw std::invalid_argument("Need at least 2 samples");
        }
        double m = mean(data);
        double sum = 0.0;
        for (const auto& v : data) {
            sum += std::pow(static_cast<double>(v) - m, 2);
        }
        return std::sqrt(sum / (data.size() - 1));
    }

    template <std::ranges::range Range>
    static auto filter_outliers(const Range& data, double threshold = 2.0) {
        std::vector<typename Range::value_type> result;
        auto m = mean(std::vector(data.begin(), data.end()));
        auto s = stddev(std::vector(data.begin(), data.end()));
        for (const auto& v : data) {
            if (std::abs(static_cast<double>(v) - m) <= threshold * s) {
                result.push_back(v);
            }
        }
        return result;
    }
};

// ---------- Custom Exception ----------

class MathException : public std::exception {
private:
    std::string message_;
public:
    explicit MathException(std::string msg) : message_(std::move(msg)) {}
    const char* what() const noexcept override {
        return message_.c_str();
    }
};

// ---------- Function Parser (simple) ----------

template <FloatingPoint T>
class Function {
public:
    using FuncType = std::function<T(T)>;

    explicit Function(FuncType f) : f_(std::move(f)) {}

    T operator()(T x) const { return f_(x); }

    Function derivative(T h = T(1e-6)) const {
        return Function([this, h](T x) {
            return (f_(x + h) - f_(x - h)) / (T(2) * h);
        });
    }

    T integrate(T a, T b, int steps = 1000) const {
        T h = (b - a) / steps;
        T sum = T(0);
        for (int i = 0; i < steps; ++i) {
            sum += f_(a + h * (i + T(0.5)));
        }
        return sum * h;
    }

private:
    FuncType f_;
};

} // namespace devmedia::math

// ---------- Main ----------

int main() {
    using namespace devmedia::math;

    // Vector operations
    Vector<double, 3> v1{1.0, 2.0, 3.0};
    Vector<double, 3> v2{4.0, 5.0, 6.0};

    std::cout << "v1 = " << v1 << "\n";
    std::cout << "v2 = " << v2 << "\n";
    std::cout << "v1 + v2 = " << (v1 + v2) << "\n";
    std::cout << "v1 dot v2 = " << v1.dot(v2) << "\n";
    std::cout << "|v1| = " << v1.magnitude() << "\n";

    // Matrix operations
    Matrix<double, 2, 2> m1;
    m1[0][0] = 1; m1[0][1] = 2;
    m1[1][0] = 3; m1[1][1] = 4;

    auto m2 = Matrix<double, 2, 2>::identity();
    auto product = m1 * m2;
    std::cout << "\nMatrix product:\n";
    for (size_t i = 0; i < product.rows(); ++i) {
        for (size_t j = 0; j < product.cols(); ++j) {
            std::cout << product[i][j] << " ";
        }
        std::cout << "\n";
    }

    // Statistics
    std::vector<double> data{2.5, 3.7, 4.1, 2.9, 3.3, 10.2, 3.1, 2.8};
    std::cout << "\nStatistics:\n";
    std::cout << "Mean: " << Statistics<double>::mean(data) << "\n";
    std::cout << "Median: " << Statistics<double>::median(data) << "\n";
    std::cout << "StdDev: " << Statistics<double>::stddev(data) << "\n";

    auto filtered = Statistics<double>::filter_outliers(data);
    std::cout << "After removing outliers: ";
    for (const auto& v : filtered) {
        std::cout << v << " ";
    }
    std::cout << "\n";

    // Function calculus
    auto f = Function<double>([](double x) { return std::sin(x); });
    std::cout << "\nCalculus:\n";
    std::cout << "sin(pi/2) = " << f(Constants<double>::pi / 2) << "\n";
    std::cout << "cos(0) ≈ " << f.derivative()(0.0) << "\n";
    std::cout << "∫sin(x) dx [0,π] = " << f.integrate(0.0, Constants<double>::pi) << "\n";

    return 0;
}
