#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#ifndef SMARTMATH_COMPLEX_NUMBERS
#define SMARTMATH_COMPLEX_NUMBERS 1
#endif

#ifndef SMARTMATH_TIME_VALUES
#define SMARTMATH_TIME_VALUES 1
#endif

#ifndef SMARTMATH_FACTORINT
#define SMARTMATH_FACTORINT 1
#endif

#ifndef SMARTMATH_LAMBDA_FUNCTIONS
#define SMARTMATH_LAMBDA_FUNCTIONS 1
#endif

class MathParser {
public:
  struct RawResult {
    enum class Kind { None, Scalar, Array };
    enum class ScalarKind { FloatingPoint, Int64, UInt64, Rational,
#if SMARTMATH_FACTORINT
                            IntPower,
#endif
                            Complex, Time };

    /// One real or imaginary component. Only the union member for ``kind`` is meaningful.
    struct CartesianScalar {
      ScalarKind kind = ScalarKind::FloatingPoint;
      union {
        double floatingPoint;    // valid for FloatingPoint
        long long intValue;      // valid for Int64 and Time (total milliseconds)
        std::uint64_t uintValue; // valid for UInt64
        struct {
          long long numerator;
          std::uint64_t denominator;
        } rational;              // valid for Rational
      };

      CartesianScalar() : floatingPoint(0.0) {}

      bool isFloatingPoint() const { return kind == ScalarKind::FloatingPoint; }
      bool isInt64() const { return kind == ScalarKind::Int64; }
      bool isUInt64() const { return kind == ScalarKind::UInt64; }
      bool isRational() const { return kind == ScalarKind::Rational; }
#if SMARTMATH_FACTORINT
      bool isIntPower() const { return kind == ScalarKind::IntPower; }
#endif
      bool isTime() const { return kind == ScalarKind::Time; }
    };

    /// Non-complex: payload in ``real`` only; ``imag`` cleared; ``kind`` mirrors ``real.kind``.
    /// Complex: ``kind == Complex``; each part uses ``real`` / ``imag``.
    /// Rational -> real.rational member.
    /// Time -> real.intValue ms.
    struct Scalar {
      ScalarKind kind = ScalarKind::FloatingPoint;
      CartesianScalar real{};
      CartesianScalar imag{};

      bool isComplex() const { return kind == ScalarKind::Complex; }
      bool isFloatingPoint() const { return !isComplex() && real.isFloatingPoint(); }
      bool isInt64() const { return !isComplex() && real.isInt64(); }
      bool isUInt64() const { return !isComplex() && real.isUInt64(); }
      bool isRational() const { return !isComplex() && real.isRational(); }
      bool isTime() const { return !isComplex() && real.isTime(); }
    };

    /// None: no value available (for example, after evaluation error).
    /// Scalar: scalar field is valid, array is empty.
    /// Array: array field is valid, scalar should be ignored.
    Kind kind = Kind::None;
    /// Meaningful only when kind == Scalar; otherwise ignore.
    Scalar scalar{};
    /// Meaningful only when kind == Array; otherwise empty.
    std::vector<Scalar> array;

    bool hasValue() const { return kind != Kind::None; }
    bool isScalar() const { return kind == Kind::Scalar; }
    bool isArray() const { return kind == Kind::Array; }
  };

  MathParser();

  /// Parse into an internal program (AST). O(expression length). Does not evaluate.
  /// On failure, getError() is non-empty and no program is retained.
  bool compile(const std::string& mathExpression);

  /// Run the last successful compile() against the current variables, constants, and user functions.
  /// Repeated calls re-evaluate without re-parsing. Fails if compile() was never successful.
  void evaluate();

  /// Equivalent to compile() followed by evaluate() when you only need a single shot.
  void parseAndEvaluate(const std::string& mathExpression);
  /// Single-shot parse+evaluate that returns raw value directly; returns empty RawResult on error.
  RawResult parseAndEvaluateRaw(const std::string& mathExpression);

  std::string getError() const;
  std::string getResult() const;
  std::string getResultAsHex() const;
  std::string getResultAsDec() const;
  std::string getResultAsOct() const;
  std::string getResultAsBin() const;
  RawResult getRawResult() const;

  /// When false (default), the parser keeps real-only scalar semantics for non-finite or non-real outcomes.
  /// When true, future releases may evaluate complex-valued builtins and accept complex literals/arrays.
  void setSupportComplexNumbers(bool enabled);
  bool getSupportComplexNumbers() const;
  void setSupportTimeValues(bool enabled);
  bool getSupportTimeValues() const;
  void setSupportLambdaFunctions(bool enabled);
  bool getSupportLambdaFunctions() const;

  void addConst(const std::string& constName, long long intValue);
  void addConst(const std::string& constName, double dblValue);
  std::string addUserFunction(const std::string& mathExpression);

private:
  enum class BuiltinFunctionId {
    Rand = 0,
    Random,
    Bin,
    Hex,
    Oct,
    Pow,
    Atan2,
    Sin,
    Cos,
    Tan,
    Asin,
    Acos,
    Atan,
    Sinh,
    Cosh,
    Tanh,
    Acosh,
    Asinh,
    Atanh,
    Exp,
    Log,
    Ln,
    Log10,
    Sqrt,
    Sqr,
    Int,
    Frac,
    Abs,
    Floor,
    Ceil,
    Trunc,
    Round,
    Sign,
    Deg,
    Rad,
    Sum,
    Median,
    Variance,
    Stddev,
    Sort,
    Sortby,
    Ratio,
    Reverse,
    Unique,
    Unpack,
    Fact,
    Factorint,
    Avg,
    Mean,
    Mod,
    Clamp,
    Hypot,
    Gcd,
    Lcm,
    Ncr,
    Npr,
    Product,
    Min,
    Max,
    Uhex,
    Uoct,
    Ubin,
    Milliseconds,
    Seconds,
    Minutes,
    Hours,
    Days,
    Real,
    Imag,
    Phase,
    Polar,
    Cart,
    Conj,
    Count
  };

  enum class OperatorNameId {
    Not = 0,
    And,
    Or,
    Count
  };

  enum class BuiltinHintKind {
    None = 0,
    EmptyPar,
    MinMax,
    DotDotDot,
    ValuePower,
    YX,
    Angle,
    Value,
    ValueBase,
    N,
    ValueDivisor,
    ValueMinMax,
    XY,
    AB,
    ArrayFunc
  };

  enum class ValueKind { Scalar, Array, FunctionRef, InlineLambda, UdfFormalValidationDummy };
  enum class ScalarKind { FloatingPoint, Int64, UInt64, Time };

  enum class RenderBase { Dec = 10, Hex = 16, Oct = 8, Bin = 2 };

  struct EvalValue {
    struct ScalarValue {
      enum : unsigned int {
        fExactInt64Valid = 0x01u,
        fExactUInt64Valid = 0x02u,
        fDecScientificPow63High = 0x10u,
        fImagExactInt64Valid = 0x20u,
        fImagExactUInt64Valid = 0x40u,
        fRenderRational = 0x80u,
        fImagRenderRational = 0x100u
#if SMARTMATH_FACTORINT
        ,
        fRenderIntPower = 0x200u
#endif
      };
      ScalarKind scalarKind = ScalarKind::FloatingPoint;
      unsigned int flags = 0;
      double scalar = 0.0;
      long long exactInt64 = 0;
      std::uint64_t exactUInt64 = 0;
      double imag = 0.0;
      long long imagExactInt64 = 0;
      std::uint64_t imagExactUInt64 = 0;

      bool hasExactInt64() const { return (flags & fExactInt64Valid) != 0; }
      void setExactInt64Valid(bool v) { flags = v ? (flags | fExactInt64Valid) : (flags & ~fExactInt64Valid); }
      bool hasExactUInt64() const { return (flags & fExactUInt64Valid) != 0; }
      void setExactUInt64Valid(bool v) { flags = v ? (flags | fExactUInt64Valid) : (flags & ~fExactUInt64Valid); }
      bool hasDecScientificPow63High() const { return (flags & fDecScientificPow63High) != 0; }
      void setDecScientificPow63High(bool v) {
        flags = v ? (flags | fDecScientificPow63High) : (flags & ~fDecScientificPow63High);
      }
      bool hasImagExactInt64() const { return (flags & fImagExactInt64Valid) != 0; }
      void setImagExactInt64Valid(bool v) { flags = v ? (flags | fImagExactInt64Valid) : (flags & ~fImagExactInt64Valid); }
      bool hasImagExactUInt64() const { return (flags & fImagExactUInt64Valid) != 0; }
      void setImagExactUInt64Valid(bool v) {
        flags = v ? (flags | fImagExactUInt64Valid) : (flags & ~fImagExactUInt64Valid);
      }
      bool hasRenderRational() const { return (flags & fRenderRational) != 0; }
      void setRenderRational(bool v) { flags = v ? (flags | fRenderRational) : (flags & ~fRenderRational); }
      bool hasImagRenderRational() const { return (flags & fImagRenderRational) != 0; }
      void setImagRenderRational(bool v) {
        flags = v ? (flags | fImagRenderRational) : (flags & ~fImagRenderRational);
      }
#if SMARTMATH_FACTORINT
      bool hasRenderIntPower() const { return (flags & fRenderIntPower) != 0; }
      void setRenderIntPower(bool v) { flags = v ? (flags | fRenderIntPower) : (flags & ~fRenderIntPower); }
#endif
    };

    enum : unsigned int {
      fExpandArgs = 0x01u,   // Used by unpack(...): marks values for call-argument expansion.
      fRenderUnsigned = 0x02u, // For hex/oct/bin output: render negative integers as unsigned bit pattern.
      fRenderBaseMask = 0x0000FF00u, // Bit mask for packed RenderBase storage in flags.
      fRenderBaseShift = 8u // Bit shift for packed RenderBase storage in flags.
    };
    ValueKind kind = ValueKind::Scalar;
    unsigned int flags = 0;
    ScalarValue scalarValue{};
    std::vector<ScalarValue> arr;
    std::string funcRefName;
    /** Only when ``kind`` is InlineLambda (anonymous lambdas inside ``sortby``). */
    std::vector<std::string> lambdaParams;
    std::string lambdaBody;
    /// When true with hex/oct/bin output, format negative integers as unsigned (two's complement) bit pattern.
    bool hasExpandArgs() const { return (flags & fExpandArgs) != 0; }
    void setExpandArgs(bool v) { flags = v ? (flags | fExpandArgs) : (flags & ~fExpandArgs); }
    bool hasRenderUnsigned() const { return (flags & fRenderUnsigned) != 0; }
    void setRenderUnsigned(bool v) { flags = v ? (flags | fRenderUnsigned) : (flags & ~fRenderUnsigned); }
    RenderBase getRenderBase() const {
      const unsigned int raw = (flags & fRenderBaseMask) >> fRenderBaseShift;
      return (raw == 0u) ? RenderBase::Dec : static_cast<RenderBase>(raw);
    }
    void setRenderBase(RenderBase v) {
      flags = (flags & ~fRenderBaseMask) |
              ((static_cast<unsigned int>(v) & 0xFFu) << fRenderBaseShift);
    }
  };

  struct AstStatement;

  struct UserFunction {
    std::string name;
    std::vector<std::string> params;
    std::string expr;
    std::vector<AstStatement> compiledProgram;
    bool compiledProgramReady = false;
  };

  struct Expr {
    enum class Tag {
      Literal,
      Variable,
      Unary,
      Binary,
      Call,
      Index,
      ArrayOrParens,
      PostfixPercent,
      FunctionRef
    };
    enum class BinaryOp {
      None = 0,
      LogicalOr,
      LogicalAnd,
      Modulo,
      BitAnd,
      BitOr,
      BitXor,
      ShiftLeft,
      ShiftRight,
      CmpLt,
      CmpGt,
      CmpLe,
      CmpGe,
      CmpEq,
      CmpNe,
      Add,
      Sub,
      Mul,
      Div,
      Pow
    };
    Tag tag = Tag::Literal;
    EvalValue literalValue{};
    std::string name;
    BuiltinFunctionId builtinFunctionId = BuiltinFunctionId::Count;
    const EvalValue* boundVariable = nullptr;
    BinaryOp binaryOp = BinaryOp::None;
    bool rhsIsDirectPostfixPercent = false;
    char unaryOp = 0;
    std::unique_ptr<Expr> child;
    std::unique_ptr<Expr> left;
    std::unique_ptr<Expr> right;
    std::vector<std::unique_ptr<Expr>> elements;
  };

  struct AstStatement {
    enum class Kind { FunDef, Assign, Expr };
    Kind kind = Kind::Expr;
    UserFunction fun;
    std::string assignName;
    std::unique_ptr<Expr> expr;
  };

  struct EvalContext {
    const char* p = nullptr;
    const char* start = nullptr;
    std::string sourceExpr;
    bool parseError = false;
    std::string errorText;
    bool wasPercentage = false;
    int evalDepth = 0;
    /** Collected like FreeBASIC (non-fatal until end of eval). */
    std::string unknownVarsText;
    std::string unknownFuncsText;
    /** Params of UDFs seen earlier in the program currently being compiled (not yet in userFunctions_). */
    const std::unordered_map<std::string, std::vector<std::string>>* compilingUserFunctionParams = nullptr;
  };

  EvalValue lastResult_;
  bool hasResult_ = false;
  std::string lastError_;
  std::unordered_map<std::string, EvalValue> variables_;
  std::vector<UserFunction> userFunctions_;
  std::unordered_map<std::string, std::size_t> userFunctionIndex_;
  /** Active user-defined function names during one evaluate(); detects mutual recursion. */
  std::vector<std::string> userFunctionCallStack_;
  std::vector<AstStatement> compiledProgram_;
  mutable std::vector<EvalValue> scratchExpandedArgs_;
  mutable std::vector<EvalValue> scratchBinaryOut_;
  mutable std::vector<EvalValue> scratchClampOut_;
  std::size_t variablesVersion_ = 0;
  std::size_t boundVariablesVersion_ = static_cast<std::size_t>(-1);
  bool compiledHasAssignments_ = false;
  bool hasCompiledProgram_ = false;
  bool compiledScalarOnly_ = false;
  bool supportComplexNumbers_ = false;
  bool supportTimeValues_ = true;
  bool supportLambdaFunctions_ = true;
  std::unique_ptr<Expr> (MathParser::*parseSortbyKeyArgImpl_)(EvalContext&);
  /** Owned compile buffer when input needs comment/semicolon stripping; otherwise compile borrows input. */
  std::string compileParseStorage_;

  bool prepareCompileParseSource(const std::string& mathExpression, EvalContext& ctx);
  static std::string toLower(std::string s);
  static bool isIdentStart(char c);
  static bool isIdentChar(char c);
  static bool isNumericLiteralStart(char c);
  static std::string consumeLowerIdentToken(EvalContext& ctx);
  bool tryConsumeCommaArgSeparator(EvalContext& ctx, bool& hasComma) const;
  static void skipSpaces(EvalContext& ctx);
  void setUnexpectedTokenError(EvalContext& ctx) const;
  void setUnexpectedInputError(EvalContext& ctx) const;
  void setMissingClosingParenLikeError(EvalContext& ctx) const;
  static bool consumeKeyword(EvalContext& ctx, const char* kw);
  bool tryConsumeLogicalBinaryOperator(EvalContext& ctx, OperatorNameId keywordId, char symbol) const;
  static std::unique_ptr<Expr> makeBinaryExpr(
      std::unique_ptr<Expr> left,
      std::unique_ptr<Expr> right,
      Expr::BinaryOp op,
      bool setPercentFlag);
  bool parseParenthesizedExprList(
      EvalContext& ctx,
      std::vector<std::unique_ptr<Expr>>& outValues);
  std::unique_ptr<Expr> parsePrimaryParenthesized(EvalContext& ctx);
  std::unique_ptr<Expr> parsePrimaryNumericLiteral(EvalContext& ctx);
#if SMARTMATH_TIME_VALUES
  bool tryParseScalarTimeLiteral(EvalContext& ctx, EvalValue& out) const;
  bool tryParseCompactSuffixTimeLiteral(EvalContext& ctx, EvalValue& out) const;
#endif
  std::unique_ptr<Expr> parsePrimaryIdentifierOrCall(EvalContext& ctx);
  bool parseSortbyCallArguments(EvalContext& ctx, std::vector<std::unique_ptr<Expr>>& outArgs);
  std::unique_ptr<Expr> parseSortbyFunctionRef(EvalContext& ctx);
  enum class LambdaBodyStop {
    WrappedParenClose,
    SortbyArgDelim,
    TopLevelSemicolonOrEof,
    ToEof
  };
#if SMARTMATH_LAMBDA_FUNCTIONS
  bool tryConsumeLambdaParameterList(EvalContext& ctx, std::vector<std::string>& outParams, bool quiet) const;
  static bool lambdaBodyConsume(
      EvalContext& ctx,
      std::string& outBody,
      LambdaBodyStop stop,
      const char* sortbyLambdaKeyStart);
  bool tryParseLambdaInnerUnwrappedSuffix(
      EvalContext& ctx,
      std::vector<std::string>& outParams,
      std::string& outBody,
      LambdaBodyStop bodyStop,
      const char* sortbyLambdaKeyStart,
      bool quiet) const;
  bool tryParseLambdaRhsAfterEquals(EvalContext& ctx, std::vector<std::string>& outParams, std::string& outExpr) const;
  std::unique_ptr<Expr> makeUnarySortbyInlineLambdaExpr(
      EvalContext& ctx,
      std::vector<std::string>&& params,
      std::string&& body);
  std::unique_ptr<Expr> parseSortbyKeyArgWithLambda(EvalContext& ctx);
  static EvalValue makeInlineLambdaValue(std::vector<std::string> params, std::string body);
  EvalValue evalInlineLambdaCall(
      EvalContext& ctx,
      const std::vector<std::string>& paramNames,
      const std::string& bodyExpr,
      std::vector<EvalValue>&& args,
      const std::unordered_map<std::string, EvalValue>* scopedVars);
#endif
  std::unique_ptr<Expr> parseSortbyKeyArg(EvalContext& ctx);
  std::unique_ptr<Expr> parseSortbyKeyArgFunctionRefOnly(EvalContext& ctx);
  void syncLambdaSupportDispatch();
  static bool isTruthy(const EvalValue& v);
  static std::string trim(const std::string& s);
  static bool udfBodyIsEmptyTupleLiteral(const std::string& bodyExpr);
  static bool nearlyInt(double v, long long& out);
  static bool parseUInt64FromDouble(double v, std::uint64_t& out);
  static bool tryGetExactSignedInt64FromScalar(const EvalValue::ScalarValue& s, long long& outI);
  static bool tryGetExactImagInt64Strict(const EvalValue::ScalarValue& s, long long& outI);
  static bool tryGetExactSignedInt64NoUIntWrapFromScalar(const EvalValue::ScalarValue& s, long long& outI);
  static void scalarRepairExactMetadata(EvalValue::ScalarValue& s);
  static bool scalarHasExactIntegerPayload(const EvalValue::ScalarValue& s);
  static bool tryMulExactInt64Square(long long i, long long& outSq);
  static bool tryGetExactSignedInt64NoUIntWrapScalarStrict(const EvalValue::ScalarValue& s, long long& outI);
  static void applySqrtScalarValue(const EvalValue::ScalarValue& sv, EvalValue& outV);
  static bool tryApplySqrExactScalar(const EvalValue::ScalarValue& sv, EvalValue& outV);
  static bool tryApplyHypotExactScalars(
      const EvalValue::ScalarValue& leftS,
      const EvalValue::ScalarValue& rightS,
      EvalValue& outV);
  static bool tryApplyPowExactScalarsSignedInt(
      long long valueInt,
      const EvalValue::ScalarValue& leftS,
      const EvalValue::ScalarValue& rightS,
      EvalValue& outV);
  static bool tryApplyPowExactScalarsUInt(
      std::uint64_t inpU,
      const EvalValue::ScalarValue& leftS,
      const EvalValue::ScalarValue& rightS,
      EvalValue& outV);
  static bool tryApplyPowExactScalars(
      const EvalValue::ScalarValue& leftS,
      const EvalValue::ScalarValue& rightS,
      EvalValue& outV);
  static bool tryApplyRealScalarPowNegFractional(
      const EvalValue::ScalarValue& leftS,
      double p,
      EvalValue& outV);
  static bool tryApplyScalarPowSpecialPaths(
      const EvalValue::ScalarValue& leftS,
      const EvalValue::ScalarValue& rightS,
      EvalValue& outV);
#if SMARTMATH_COMPLEX_NUMBERS
  static bool tryRefinePowPrincipalToExactScalarResult(
      const EvalValue::ScalarValue& leftS,
      const EvalValue::ScalarValue& rightS,
      double powR,
      double powI,
      EvalValue& outV);
  static bool tryVerifyComplexCartesianSquareExact(
      long long rootR, long long rootI, long long expR, long long expI);
  static bool tryRefineSqrtPrincipalToExactComplex(
      const EvalValue::ScalarValue& inS,
      double sqrtR,
      double sqrtI,
      EvalValue& outV);
  static EvalValue applySqrtComplexPrincipalUnary(const EvalValue::ScalarValue& inS);
  void applyComplexCaretPrincipalEval(
      const EvalValue::ScalarValue& lv,
      const EvalValue::ScalarValue& rv,
      EvalValue& outS) const;
#endif
  EvalValue applyUnarySqrtEval(const EvalValue::ScalarValue& s) const;
  static bool tryGetExactNonNegativeUInt64FromScalar(const EvalValue::ScalarValue& s, std::uint64_t& outU);
  static bool tryGetBothExactSignedInt64NoUIntWrapFromScalars(
      const EvalValue::ScalarValue& a,
      const EvalValue::ScalarValue& b,
      long long& outA,
      long long& outB);
  static bool tryGetBothExactNonNegativeUInt64FromScalars(
      const EvalValue::ScalarValue& a,
      const EvalValue::ScalarValue& b,
      std::uint64_t& outA,
      std::uint64_t& outB);
  static bool tryShiftLeftU64ExactOrMaybe(
      std::uint64_t aU,
      std::uint64_t bU,
      EvalValue& outV);
  static bool tryGetSignedInt64FromScalar(const EvalValue::ScalarValue& s, long long& outI);
  static bool argsContainNonFinite(const std::vector<EvalValue>& args);
  // Builtin metadata tables are embedded in parser sources (MathParser.cpp / MathParser.bas).
  // Builtin validation flags (keep in sync with BUILTIN_FLAG_* / GetBuiltinFlags in MathParser.bas).
  enum class BuiltinFlags : unsigned {
    None = 0,
    Unary = 1u << 0,
    Format = 1u << 1,
    IntegerOnly = 1u << 2,
    NonCalculating = 1u << 3,
    FiniteRequired = 1u << 4,
    TrailingFormatter = 1u << 5,
  };
  friend constexpr BuiltinFlags operator|(BuiltinFlags a, BuiltinFlags b) noexcept;
  struct BuiltinMetaRow {
    BuiltinFlags flags;
    std::uint8_t minArgs;
    std::uint8_t maxArgs;
    BuiltinHintKind hintKind;
  };
  static constexpr std::uint8_t kBuiltinMetaArityUnset = 254;
  static const BuiltinMetaRow kBuiltinMeta[];
  friend constexpr std::size_t builtinMetaRowCountForAssert();
  static BuiltinFlags getBuiltinFlags(BuiltinFunctionId id);
  static bool hasBuiltinFlag(BuiltinFunctionId id, BuiltinFlags flag);
  static constexpr uint8_t kBuiltinArityUnbounded = 255;
  static bool getBuiltinArity(BuiltinFunctionId id, uint8_t& minArgs, uint8_t& maxArgs);
  bool validateCallArity(
      EvalContext& ctx,
      const std::string& fnName,
      uint8_t minArgs,
      uint8_t maxArgs,
      std::size_t argc) const;
  bool validateBuiltinCallArity(
      EvalContext& ctx,
      const std::string& fnName,
      BuiltinFunctionId id,
      const std::vector<EvalValue>& args) const;
  bool validateIntegerRepresentableArgs(
      EvalContext& ctx,
      const std::string& fnName,
      const std::vector<EvalValue>& args,
      bool allowNonFiniteForFormat) const;
  bool validateBuiltinArgs(
      EvalContext& ctx,
      const std::string& fnName,
      BuiltinFunctionId id,
      const std::vector<EvalValue>& args) const;
  static bool isPureFloatingScalarPair(const EvalValue::ScalarValue& a, const EvalValue::ScalarValue& b);

  std::string formatScalar(const EvalValue& v, RenderBase base) const;
  std::string valueToString(const EvalValue& v, RenderBase forcedBase) const;
  std::string valueToString(const EvalValue& v) const;
  static const std::vector<std::string>& functionNames();
  static const std::unordered_map<std::string, BuiltinFunctionId>& functionNameToId();
  static const std::vector<std::string>& operatorNames();
  static const std::string& getFunctionName(BuiltinFunctionId id);
  static const std::string& opName(OperatorNameId id);
  static bool tryGetBuiltinFunctionId(const std::string& nameText, BuiltinFunctionId& outId);
  static BuiltinHintKind getBuiltinHintKind(BuiltinFunctionId id);
  static std::string getBuiltinFunctionMissingCallHint(BuiltinFunctionId id);
  static bool isOpKeyword(const std::string& nameText, OperatorNameId id);
  static bool isLogicalBinaryOperatorKeyword(const std::string& nameText);
  static bool isReservedFunctionName(const std::string& nameText);
  const char* getReservedIdentifierError(const std::string& ident) const;
  static bool isTrailingFormatterFunctionName(const std::string& nameText);
  bool isBareFunctionNameAtExpressionTail(EvalContext& ctx, const char* identStart) const;
  bool trySetBareFunctionImmediateCloserError(EvalContext& ctx, const char* identStart) const;
  bool tryApplyExactIntegerDivisionFromQuotient(
      const EvalValue::ScalarValue& leftS,
      const EvalValue::ScalarValue& rightS,
      double r,
      EvalValue& outV) const;
  bool identIsBareFunctionOrUdfName(const std::string& ident, const EvalContext& ctx) const;
  bool trimmedStmtIsBareFunctionOrUdfName(const std::string& stmt) const;
  bool trimmedStmtIsBareFunctionOrUdfName(const char* begin, const char* end) const;
  void stripTrailingSemicolonsForTopLevelInput(std::string& s) const;
  bool trySetMissingFunctionCallError(
      EvalContext& ctx,
      const std::string& ident,
      const char* identStart) const;
  bool trySetIncompleteOpenedFunctionCallHint(
      EvalContext& ctx,
      const std::string& ident,
      const char* fnIdentStart) const;
  bool trySetBareUserFunctionNameError(
      EvalContext& ctx,
      const std::string& ident,
      const char* identStart) const;
  static std::string formatUserFunctionSignature(const UserFunction& uf);
  bool handleUnknownIdentifier(EvalContext& ctx, const std::string& ident, std::string& unknownList) const;
  bool tryResolveVariableValue(
      const Expr& e,
      const std::unordered_map<std::string, EvalValue>* scopedVars,
      EvalValue& out) const;
  static EvalValue makeUdfFormalValidationDummy();
  const char* validateUserFunctionDefinitionNames(
      const std::string& fnName,
      const std::vector<std::string>& fnParams) const;
  std::string getUserFunctionDefinitionErrorText(
      const std::string& fnName,
      const std::vector<std::string>& fnParams,
      const std::string& fnExpr,
      bool evaluateBody);
  bool trySetUserFunctionDefinitionError(
      EvalContext& ctx,
      const std::string& fnName,
      const std::vector<std::string>& fnParams,
      const std::string& fnExpr);
  const char* validateAssignmentTargetName(const std::string& ident) const;
  static std::string buildUnknownVariableErrorText(const std::string& unknownVarsText);
  static std::string buildUnknownFunctionErrorText(const std::string& unknownFuncsText);
  static void appendUnknownFunctionErrorText(std::string& errorText, const std::string& unknownFuncsText);
  void setValidationError(EvalContext& ctx, const char* errorText) const;
  bool trySetUnknownNameError(const EvalContext& ctx);
  static std::string buildUnknownNameErrorText(
      const std::string& unknownVarsText,
      const std::string& unknownFuncsText);
  bool tryAppendParsedExpressionStatement(
      EvalContext& ctx,
      std::vector<AstStatement>& out);
  bool tryAppendFunctionDefinitionStatement(
      EvalContext& ctx,
      std::vector<AstStatement>& out);
  bool tryAppendAssignOrExpressionStatement(
      EvalContext& ctx,
      std::vector<AstStatement>& out);
  bool consumeProgramStatementSeparator(EvalContext& ctx);
  bool tryAppendTrailingFormatterSugarStatement(
      EvalContext& ctx,
      std::vector<AstStatement>& out,
      bool& handled);
  static bool hasExprParseFailure(const EvalContext& ctx, const std::unique_ptr<Expr>& node);
  void setNumericErrorInFunction(EvalContext& ctx, const std::string& fnName) const;
  void setAtLeastOneArgError(EvalContext& ctx, const std::string& fnName) const;
  void setExactArgCountError(EvalContext& ctx, const std::string& fnName, size_t expectedCount) const;
#if SMARTMATH_TIME_VALUES
  bool rejectBinaryBuiltinTimeOperands(EvalContext& ctx, const EvalValue& left, const EvalValue& right) const;
  bool rejectNumericBinaryPowWithTime(
      EvalContext& ctx,
      const EvalValue& left,
      const EvalValue& right,
      char op) const;
#endif
  bool rejectInt64BinaryOperands(
      EvalContext& ctx,
      const EvalValue& left,
      const EvalValue& right,
      bool isModulo) const;
  EvalValue builtinMapBinaryTwoArg(
      EvalContext& ctx,
      const std::string& fnName,
      BuiltinFunctionId id,
      const std::vector<EvalValue>& args,
      bool rejectComplexOperands,
      bool numericErrorOnMapFailure) const;
  template <typename Visitor>
  static std::size_t forEachCallArgScalarValues(const std::vector<EvalValue>& args, Visitor&& visit) {
    std::size_t count = 0;
    for (const auto& a : args) {
      if (a.kind == ValueKind::Scalar) {
        visit(a.scalarValue);
        ++count;
      } else {
        for (const auto& item : a.arr) {
          visit(item);
          ++count;
        }
      }
    }
    return count;
  }
  void setScalarValuesError(EvalContext& ctx, const std::string& fnName) const;
  void setIntegerValuesError(EvalContext& ctx, const std::string& fnName) const;
  void setScalarMinMaxError(EvalContext& ctx, const std::string& fnName) const;
  void setNonNegativeIntegerError(EvalContext& ctx, const std::string& fnName) const;
  void setBitwiseIntegerOperandsError(EvalContext& ctx) const;
  void setModuloIntegerOperandsError(EvalContext& ctx) const;
  void setIncompatibleOperandsError(EvalContext& ctx) const;
  bool evalValuesHaveMismatchedArrayLengths(const EvalValue& left, const EvalValue& right) const;
  void setBinaryBuiltinBroadcastFailure(
      EvalContext& ctx,
      const std::string& fnName,
      const EvalValue& left,
      const EvalValue& right,
      int pairStatus) const;
  void setUnexpectedCommaError(EvalContext& ctx) const;
  void setIndexingRequiresArrayError(EvalContext& ctx) const;
  void setMissingIndexError(EvalContext& ctx) const;
  void setArrayIndexMustBeScalarError(EvalContext& ctx) const;
  void setArrayIndexMustBeIntegerError(EvalContext& ctx) const;
  void setArrayIndexOutOfRangeError(EvalContext& ctx) const;
  void setMissingClosingBracketError(EvalContext& ctx) const;
  void setMissingClosingParenthesisError(EvalContext& ctx) const;
  void setFunctionHintError(EvalContext& ctx, const std::string& hintText) const;
  void setInvalidHexLiteralError(EvalContext& ctx) const;
  void setInvalidBinaryLiteralError(EvalContext& ctx) const;
  void setInvalidOctalLiteralError(EvalContext& ctx) const;
  void setInvalidPrefixedLiteralError(EvalContext& ctx, char prefixChar) const;
  void setInternalUnaryOpError(EvalContext& ctx) const;
  void setInternalBinaryOpError(EvalContext& ctx) const;
  void setInternalEvalError(EvalContext& ctx) const;
  void setNumericErrorInPowerOperation(EvalContext& ctx) const;
  void setNumericErrorInExpression(EvalContext& ctx) const;
  void setUserFunctionCallStackOverflowError(EvalContext& ctx) const;
  void setRecursiveUserFunctionCallError(EvalContext& ctx, const std::string& fnName) const;
  void setMaxEvaluationDepthReachedError(EvalContext& ctx) const;
  void setInvalidNumericLiteralError(EvalContext& ctx) const;
  void setPercentageRequiresScalarValueError(EvalContext& ctx) const;
  void setFailedToBuildArrayLiteralError(EvalContext& ctx) const;
  void setInternalAggregateBuiltinError(EvalContext& ctx) const;
  void setInternalScalarBinaryBuiltinError(EvalContext& ctx) const;
  void setInternalUnaryMathBuiltinError(EvalContext& ctx) const;
  void setUnexpectedTokenAfterExpressionError(EvalContext& ctx) const;
  void setScalarOnlyExpressionEncounteredNonError(EvalContext& ctx) const;
  void setParseFailedError(EvalContext& ctx) const;
  void setStaticError(EvalContext& ctx, const char* errorText) const;

  void setError(EvalContext& ctx, const std::string& msg) const;

  bool tryCompileSingleExpressionProgram(EvalContext& ctx, std::vector<AstStatement>& out);
  bool parseProgram(EvalContext& ctx, std::vector<AstStatement>& out);
  std::unique_ptr<Expr> parseExpression(EvalContext& ctx);
  std::unique_ptr<Expr> parseOr(EvalContext& ctx);
  std::unique_ptr<Expr> parseAnd(EvalContext& ctx);
  std::unique_ptr<Expr> parseLogicalNot(EvalContext& ctx);
  std::unique_ptr<Expr> parseCompare(EvalContext& ctx);
  std::unique_ptr<Expr> parseLeftAssocBinary(
      EvalContext& ctx,
      std::unique_ptr<Expr> (MathParser::*parseOperand)(EvalContext&),
      bool (MathParser::*tryConsumeOp)(EvalContext&, Expr::BinaryOp&),
      bool setPercentFlag = false);
  bool tryConsumeBitAndOp(EvalContext& ctx, Expr::BinaryOp& outOp);
  bool tryConsumeBitXorOp(EvalContext& ctx, Expr::BinaryOp& outOp);
  bool tryConsumeBitOrOp(EvalContext& ctx, Expr::BinaryOp& outOp);
  bool tryConsumeShiftOp(EvalContext& ctx, Expr::BinaryOp& outOp);
  bool tryConsumeAddSubOp(EvalContext& ctx, Expr::BinaryOp& outOp);
  bool tryConsumeMulDivModOp(EvalContext& ctx, Expr::BinaryOp& outOp);
  bool tryConsumeCompareOp(EvalContext& ctx, Expr::BinaryOp& outOp);
  bool tryConsumeLogicalAndOp(EvalContext& ctx, Expr::BinaryOp& outOp);
  bool tryConsumeLogicalOrOp(EvalContext& ctx, Expr::BinaryOp& outOp);
  std::unique_ptr<Expr> parseBitOr(EvalContext& ctx);
  std::unique_ptr<Expr> parseBitXor(EvalContext& ctx);
  std::unique_ptr<Expr> parseBitAnd(EvalContext& ctx);
  std::unique_ptr<Expr> parseShift(EvalContext& ctx);
  std::unique_ptr<Expr> parseAddSub(EvalContext& ctx);
  std::unique_ptr<Expr> parseMulDivMod(EvalContext& ctx);
  std::unique_ptr<Expr> parsePower(EvalContext& ctx);
  std::unique_ptr<Expr> parseUnary(EvalContext& ctx);
  std::unique_ptr<Expr> parsePrimary(EvalContext& ctx);

  EvalValue evalExpr(const Expr& e, EvalContext& ctx, const std::unordered_map<std::string, EvalValue>* scopedVars);
  EvalValue evalExprScalar(const Expr& e, EvalContext& ctx, const std::unordered_map<std::string, EvalValue>* scopedVars);
  EvalValue evalUnaryExpr(
      const Expr& e,
      EvalContext& ctx,
      const std::unordered_map<std::string, EvalValue>* scopedVars,
      bool scalarOnlyMode);
  EvalValue evalMappedBinaryOp(
      EvalContext& ctx,
      Expr::BinaryOp op,
      const EvalValue& left,
      const EvalValue& right) const;
  EvalValue evalInt64BinaryOp(
      EvalContext& ctx,
      const EvalValue& left,
      const EvalValue& right,
      Expr::BinaryOp op) const;
  static bool isComparisonBinaryOp(Expr::BinaryOp op);
  static bool evalComparisonByOp(Expr::BinaryOp op, int cmp);
  /** IEEE unordered comparison when either scalar operand is NaN (scalar-only fast path). */
  static bool evalComparisonTruthWhenUnorderedNan(Expr::BinaryOp op);
  static bool exprIsDirectPostfixPercent(const Expr& e);
  bool exprIsScalarOnly(const Expr& e) const;
  bool programIsScalarOnly(const std::vector<AstStatement>& program) const;
  EvalValue runCompiledProgram(
      EvalContext& ctx,
      const std::vector<AstStatement>& program,
      const std::unordered_map<std::string, EvalValue>* scopedVars,
      bool scalarOnlyMode = false);

  EvalValue evalFunctionCall(
      EvalContext& ctx,
      const std::string& fnName,
      std::vector<EvalValue>&& args,
      BuiltinFunctionId preboundId,
      const std::unordered_map<std::string, EvalValue>* scopedVars);

  EvalValue builtinUnpack(EvalContext& ctx, const std::vector<EvalValue>& args) const;
  EvalValue builtinAggregateFamily(
      EvalContext& ctx,
      const std::string& fnName,
      BuiltinFunctionId id,
      const std::vector<EvalValue>& args) const;
  EvalValue builtinSortFamily(
      EvalContext& ctx,
      const std::string& fnName,
      BuiltinFunctionId id,
      const std::vector<EvalValue>& args) const;
  EvalValue builtinSortby(
      EvalContext& ctx,
      const std::string& fnName,
      const std::vector<EvalValue>& args,
      const std::unordered_map<std::string, EvalValue>* scopedVars);
  EvalValue builtinRatio(EvalContext& ctx, const std::string& fnName, const std::vector<EvalValue>& args) const;
  EvalValue sortbyInvokeKeyFunction(
      EvalContext& ctx,
      const std::string& funcName,
      const EvalValue::ScalarValue& elem,
      const std::unordered_map<std::string, EvalValue>* scopedVars);
  static bool isSortbyIneligibleBuiltin(BuiltinFunctionId id);
  static bool isSortbyEligibleFunctionName(
      const MathParser& parser,
      const std::string& funcName,
      std::string& outErr);
  bool tryLexicographicCompareEvalValues(
      EvalContext& ctx,
      const EvalValue& a,
      const EvalValue& b,
      int& cmpOut) const;
  bool sortbyStableSortIndicesFromKeys(
      EvalContext& ctx,
      const std::vector<EvalValue>& sortKeys,
      std::vector<int>& orderIdx) const;
  static bool tryApproximateRational(double x, long long& num, std::uint64_t& den);
  static EvalValue makeRationalReduced(long long num, std::uint64_t den);
  bool tryBuiltinRatioScalar(EvalContext& ctx, const EvalValue::ScalarValue& sv, EvalValue& outV) const;
  static std::string formatRationalParts(long long num, std::uint64_t den);
  static bool tryFormatRationalScalar(const EvalValue::ScalarValue& sv, std::string& outText);
#if SMARTMATH_FACTORINT
  static bool tryFormatIntPowerScalar(const EvalValue::ScalarValue& sv, std::string& outText);
#endif
#if SMARTMATH_COMPLEX_NUMBERS
  static bool tryFormatComplexRationalScalar(const EvalValue::ScalarValue& sv, std::string& outText);
#endif
  EvalValue builtinBaseFormat(
      EvalContext& ctx,
      const std::string& fnName,
      BuiltinFunctionId id,
      const std::vector<EvalValue>& args) const;
  EvalValue builtinPow(EvalContext& ctx, const std::vector<EvalValue>& args) const;
  EvalValue builtinScalarBinaryFamily(
      EvalContext& ctx,
      const std::string& fnName,
      BuiltinFunctionId id,
      const std::vector<EvalValue>& args) const;
  EvalValue builtinRand(EvalContext& ctx, const std::vector<EvalValue>& args) const;
  EvalValue builtinModCall(EvalContext& ctx, const std::vector<EvalValue>& args) const;
  EvalValue builtinFactorial(
      EvalContext& ctx,
      const std::string& fnName,
      const std::vector<EvalValue>& args) const;
#if SMARTMATH_FACTORINT
  EvalValue builtinFactorint(
      EvalContext& ctx,
      const std::string& fnName,
      const std::vector<EvalValue>& args) const;
  bool tryGetFactorintInput(const EvalValue& v, bool& isNegative, std::uint64_t& absU) const;
  void appendFactorintScalarTerm(
      std::vector<EvalValue::ScalarValue>& out,
      std::uint64_t baseU,
      int expV,
      bool& applySign) const;
  static void setFactorintTermValue(
      EvalValue::ScalarValue& sv,
      long long signedValueI,
      std::uint64_t valueU,
      bool hasUIntValue);
  static void setFactorintPowerTerm(
      EvalValue::ScalarValue& sv,
      std::uint64_t baseU,
      int expV,
      long long signedValueI,
      std::uint64_t valueU,
      bool hasUIntValue);
  EvalValue buildFactorintFromAbsU(bool isNegative, std::uint64_t absU) const;
#endif
  EvalValue builtinDegRad(
      EvalContext& ctx,
      const std::string& fnName,
      BuiltinFunctionId id,
      const std::vector<EvalValue>& args) const;
  EvalValue builtinPolarCart(
      EvalContext& ctx,
      const std::string& fnName,
      BuiltinFunctionId id,
      const std::vector<EvalValue>& args) const;
  EvalValue builtinUnaryMath(
      EvalContext& ctx,
      const std::string& fnName,
      BuiltinFunctionId id,
      const std::vector<EvalValue>& args) const;
  EvalValue builtinLog(EvalContext& ctx, const std::vector<EvalValue>& args) const;
  EvalValue builtinApplyClamp(EvalContext& ctx, const EvalValue& valueV, const EvalValue& minV, const EvalValue& maxV) const;
  EvalValue evalUserFunctionCall(
      EvalContext& ctx,
      const std::string& fnName,
      const std::vector<EvalValue>& args,
      const std::unordered_map<std::string, EvalValue>* scopedVars);
  void resetCompileState();
  void resetEvaluateState();
  bool prepareEvaluate(EvalContext& ctx);
  bool finalizeEvaluate(EvalContext& ctx, EvalValue&& out);

  bool parseFunctionDefinition(
      EvalContext& ctx,
      std::string& outName,
      std::vector<std::string>& outParams,
      std::string& outExpr) const;

  static bool flattenArgs(const std::vector<EvalValue>& args, std::vector<double>& out);
  static bool flattenArgsToScalars(const std::vector<EvalValue>& args, std::vector<EvalValue>& out);
  static std::size_t countFlattenedScalars(const std::vector<EvalValue>& args);
  static int expandUnpackedArgs(const std::vector<EvalValue>& in, std::vector<EvalValue>& out);
  void setVariable(const std::string& name, const EvalValue& value);
  void removeVariableByName(const std::string& name);
  void removeUserFunctionByName(const std::string& name);
  void normalizeCallArgs(std::vector<EvalValue>& args);
  void bindExprVariableRefs(Expr& e);
  void bindCompiledVariableRefs();

  static EvalValue makeScalar(double v);
  static EvalValue makeScalarMaybeExact(double v);
  static EvalValue makeScalarInt(long long v);
  static EvalValue makeScalarUInt(std::uint64_t v);
#if SMARTMATH_TIME_VALUES
  static EvalValue makeScalarTimeMs(long long totalMs);
#endif
  static bool scalarHasNonzeroImaginaryPart(const EvalValue::ScalarValue& s);
  static void scalarClearImaginary(EvalValue::ScalarValue& s);
  static void scalarLoadCartesian(const EvalValue::ScalarValue& s, double& re, double& im);
#if SMARTMATH_COMPLEX_NUMBERS
  static EvalValue makeImaginaryUnit();
  static EvalValue makeScalarComplexFromDoubles(double re, double im);
#endif
  struct ExactCartesianComponent {
    bool hasInt = false;
    long long intV = 0;
    bool hasUInt = false;
    std::uint64_t uintV = 0;
  };
  static void exactCartesianComponentClear(ExactCartesianComponent& c);
  static void exactCartesianComponentAssignFromSignedInt64(ExactCartesianComponent& c, long long n);
  static void exactCartesianComponentAssignFromInt64(ExactCartesianComponent& c, long long n);
  static void exactCartesianComponentAssignFromUInt64(ExactCartesianComponent& c, std::uint64_t u);
  static bool tryExactCartesianComponentToInt64(const ExactCartesianComponent& c, long long& outI);
#if SMARTMATH_COMPLEX_NUMBERS
  static bool complexNeedsPrincipalNegRealPow(double ar, double ai, double br, double bi);
  static void complexCartesianBinary(double ar, double ai, double br, double bi, char op, double& outR,
                                     double& outI);
  static bool tryExtractExactImagComponent(const EvalValue::ScalarValue& sv, ExactCartesianComponent& c);
  static bool tryAddExactCartesianComponents(const ExactCartesianComponent& a,
                                             const ExactCartesianComponent& b, ExactCartesianComponent& out);
  static void scalarApplyExactImagFromCartesianComponent(EvalValue::ScalarValue& sv,
                                                         const ExactCartesianComponent& c);
  static bool trySubExactCartesianComponents(const ExactCartesianComponent& a,
                                             const ExactCartesianComponent& b, ExactCartesianComponent& out);
#endif
  static bool tryExtractExactRealComponent(const EvalValue::ScalarValue& sv, ExactCartesianComponent& c);
  static void setScalarFromExactCartesianComponent(EvalValue& v, const ExactCartesianComponent& c);
  static bool tryQuotExactInt64(long long num, long long den, long long& quo);
  static void setPureImaginaryFromMagnitudeScalar(EvalValue& outV, const EvalValue::ScalarValue& magSv);
  static bool tryNegateExactCartesianComponent(const ExactCartesianComponent& c, ExactCartesianComponent& outC);
#if SMARTMATH_COMPLEX_NUMBERS
  static void setScalarComplexFromExactCartesian(EvalValue& v, const ExactCartesianComponent& re,
                                                 const ExactCartesianComponent& im);
  static EvalValue setScalarComplexFromEvalRealImagParts(const EvalValue& rePart, const EvalValue& imPart);
  static bool tryNegateExactComplexScalar(const EvalValue::ScalarValue& sv, EvalValue& out);
  static bool tryApplyExactComplexCartesianBinary(const EvalValue::ScalarValue& leftS,
                                                  const EvalValue::ScalarValue& rightS, char op,
                                                  EvalValue& outV);
  static bool tryFoldExactComplexCartesian(const std::vector<EvalValue>& args, char op, EvalValue& out);
  bool tryApplyComplexBinaryScalars(const EvalValue::ScalarValue& lv, const EvalValue::ScalarValue& rv, char op, EvalValue& outS) const;
  static bool tryAvgExactComplexFromSum(const EvalValue& sumV, std::size_t itemCount, EvalValue& out);
  static std::string assembleComplexDecimalText(
      const std::string& rePart,
      const std::string& imagTail,
      bool negUnitImag,
      bool reZero);  
  std::string formatComplexScalarValue(const EvalValue::ScalarValue& sv) const;
  std::string formatComplexScalarWithRenderBase(const EvalValue::ScalarValue& sv, RenderBase base, bool asUnsigned) const;
  static bool isComplexUnaryTrigBuiltin(BuiltinFunctionId id);
  static bool complexUnaryTrigCartesian(BuiltinFunctionId id, double ar, double ai, double& outR, double& outI);
#endif
#if SMARTMATH_TIME_VALUES
  bool scalarValueIsTime(const EvalValue::ScalarValue& s) const;
  static long long timeTotalMsFromScalarValue(const EvalValue::ScalarValue& s);
  bool evalValueInvolvesTime(const EvalValue& v) const;
#endif
  static bool evalValueHasNonzeroImaginary(const EvalValue& v);
  enum class CmpScalarIncompatiblePolicy { SetError, SortUniqueReturnOne, SortLess, SortGreater };
  bool cmpScalarValuesForCompare(
      EvalContext* ctx,
      const EvalValue::ScalarValue& sa,
      const EvalValue::ScalarValue& sb,
      int& cmpOut,
      CmpScalarIncompatiblePolicy policy) const;
  bool rejectBuiltinArgsWithComplexImaginary(EvalContext& ctx, const std::vector<EvalValue>& args) const;
  /** @return 0 ok, 1 not integer operands, 2 lcm overflow (applyGcdLcmEvalValues also uses 3 = broadcast shape) */
  int tryApplyGcdLcmScalars(
      const EvalValue::ScalarValue& a,
      const EvalValue::ScalarValue& b,
      bool doLcm,
      EvalValue& outV) const;
  EvalValue applyGcdLcmEvalValues(const EvalValue& a, const EvalValue& b, bool doLcm, int& status) const;
  /** @return 0 ok, 1 not integer operands, 2 domain/overflow, 3 broadcast shape */
  EvalValue applyNcrNprEvalValues(const EvalValue& n, const EvalValue& r, bool doPerm, int& status) const;
  bool tryApplyModScalars(
      EvalContext& ctx,
      const std::string& fnName,
      const EvalValue::ScalarValue& a,
      const EvalValue::ScalarValue& b,
      EvalValue& out) const;
#if SMARTMATH_TIME_VALUES
  bool scalarMsForCompare(const EvalValue::ScalarValue& sv, long long& outMs) const;
  EvalValue mapTimeUnitOverArray(EvalContext& ctx, BuiltinFunctionId id, const EvalValue& inV) const;
  EvalValue evalValueFromTimeMs(BuiltinFunctionId id, long long ms) const;
#endif
  EvalValue mapUnaryComplexBuiltin(EvalContext& ctx, BuiltinFunctionId id, const EvalValue& inV) const;
  bool tryUnaryComplexBuiltinSupport(BuiltinFunctionId id, const EvalValue::ScalarValue& sv, EvalValue& out) const;
  static EvalValue makeArray(const std::vector<double>& v);
  static EvalValue makeArrayFromScalars(const std::vector<EvalValue>& v);
  static RawResult::CartesianScalar toRawCartesianScalar(const EvalValue::ScalarValue& v, bool imagPart);
  static RawResult::Scalar toRawScalar(const EvalValue::ScalarValue& v);
  static RawResult toRawResult(const EvalValue& v);
  static EvalValue scalarFromScalarValue(const EvalValue::ScalarValue& sv);
  template <typename Visitor>
  static std::size_t forEachFlattenedEvalValue(const std::vector<EvalValue>& args, Visitor&& visit) {
    std::size_t count = 0;
    for (const auto& a : args) {
      if (a.kind == ValueKind::Scalar) {
        visit(a);
        ++count;
      } else {
        for (const auto& item : a.arr) {
          visit(scalarFromScalarValue(item));
          ++count;
        }
      }
    }
    return count;
  }
  static EvalValue scalarFromArrayAt(const EvalValue& arrV, std::size_t idx);
  static bool applyBinary(double a, double b, char op, double& out);
  static EvalValue mapUnaryFn(const EvalValue& in, double (*fn)(double));
  /** Apply scalar unary logic to one element; broadcast over arrays (same pattern as mapUnaryFn). */
  template <typename ScalarFn>
  static EvalValue mapUnaryEvalValue(const EvalValue& in, ScalarFn&& applyScalar);
  template <typename ScalarFn>
  EvalValue mapBinaryBroadcast(const EvalValue& left, const EvalValue& right, ScalarFn&& scalarFn, bool& ok) const;
  EvalValue mapBinaryBuiltinMathFunction(
      const EvalValue& left,
      const EvalValue& right,
      BuiltinFunctionId id,
      bool& ok) const;
  /** Unary minus with exact int/uint preservation; LLONG_MIN -> double. */
  static EvalValue negateEvalValue(const EvalValue& v);
#if SMARTMATH_TIME_VALUES
  bool tryApplyTimeBinaryScalars(
      EvalContext& ctx,
      const EvalValue::ScalarValue& lv,
      const EvalValue::ScalarValue& rv,
      char op,
      EvalValue& outS) const;
#endif
  bool tryCombineBinaryScalars(
      EvalContext& ctx,
      char op,
      const EvalValue::ScalarValue& lv,
      const EvalValue::ScalarValue& rv,
      EvalValue& outS) const;
  EvalValue mapBinary(EvalContext& ctx, const EvalValue& a, const EvalValue& b, char op, bool& ok) const;
  UserFunction* findUserFunction(const std::string& fnName);
  const UserFunction* findUserFunction(const std::string& fnName) const;
  void upsertUserFunction(UserFunction uf);
  static EvalValue applyAbsScalarValue(const EvalValue::ScalarValue& s);
  static EvalValue calcRoundingFn(BuiltinFunctionId id, const EvalValue::ScalarValue& s);
};
