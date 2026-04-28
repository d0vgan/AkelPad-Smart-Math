#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

class MathParser {
public:
  struct RawResult {
    enum class Kind { None, Scalar, Array };
    enum class ScalarKind { FloatingPoint, Int64, UInt64 };

    struct Scalar {
      /// Active numeric representation for this scalar.
      ScalarKind kind = ScalarKind::FloatingPoint;
      /// Exactly one union member is valid, selected by kind.
      union {
        /// Valid only when kind == FloatingPoint.
        double floatingPoint;
        /// Valid only when kind == Int64.
        long long intValue;
        /// Valid only when kind == UInt64.
        std::uint64_t uintValue;
      };

      Scalar() : floatingPoint(0.0) {}
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
    Arcsin,
    Acos,
    Arccos,
    Atan,
    Arctan,
    Sinh,
    Cosh,
    Tanh,
    Exp,
    Log,
    Ln,
    Log10,
    Sqrt,
    Sqr,
    Int,
    Frac,
    Fract,
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
    Sorted,
    Reverse,
    Reversed,
    Unique,
    Unpack,
    Fact,
    Factorial,
    Avg,
    Mean,
    Mod,
    Clamp,
    Hypot,
    Gcd,
    Lcm,
    Product,
    Prod,
    Min,
    Max,
    Uhex,
    Uoct,
    Ubin,
    Count
  };

  enum class OperatorNameId {
    Not = 0,
    And,
    Or,
    Count
  };

  enum class ValueKind { Scalar, Array };
  enum class ScalarKind { FloatingPoint, Int64, UInt64 };

  enum class RenderBase { Dec = 10, Hex = 16, Oct = 8, Bin = 2 };

  struct EvalValue {
    struct ScalarValue {
      enum : unsigned int {
        fExactIntValid = 0x01u,
        fExactUInt64Valid = 0x02u,
        fDecScientificPow63High = 0x10u
      };
      ScalarKind scalarKind = ScalarKind::FloatingPoint;
      unsigned int flags = 0;
      double scalar = 0.0;
      long long exactInt = 0;
      std::uint64_t exactUInt64 = 0;

      bool hasExactInt() const { return (flags & fExactIntValid) != 0; }
      void setExactIntValid(bool v) { flags = v ? (flags | fExactIntValid) : (flags & ~fExactIntValid); }
      bool hasExactUInt64() const { return (flags & fExactUInt64Valid) != 0; }
      void setExactUInt64Valid(bool v) { flags = v ? (flags | fExactUInt64Valid) : (flags & ~fExactUInt64Valid); }
      bool hasDecScientificPow63High() const { return (flags & fDecScientificPow63High) != 0; }
      void setDecScientificPow63High(bool v) {
        flags = v ? (flags | fDecScientificPow63High) : (flags & ~fDecScientificPow63High);
      }
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
      PostfixPercent
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
    bool rhsContainsPostfixPercent = false;
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
  mutable std::vector<EvalValue> scratchLogOut_;
  mutable std::vector<EvalValue> scratchBinaryOut_;
  mutable std::vector<EvalValue> scratchClampOut_;
  std::size_t variablesVersion_ = 0;
  std::size_t boundVariablesVersion_ = static_cast<std::size_t>(-1);
  bool compiledHasAssignments_ = false;
  bool hasCompiledProgram_ = false;
  bool compiledScalarOnly_ = false;

  static std::string toLower(std::string s);
  static bool isIdentStart(char c);
  static bool isIdentChar(char c);
  static void skipSpaces(EvalContext& ctx);
  static bool consumeKeyword(EvalContext& ctx, const char* kw);
  static bool isTruthy(const EvalValue& v);
  static std::string trim(const std::string& s);
  static bool nearlyInt(double v, long long& out);
  static bool parseUInt64FromDouble(double v, std::uint64_t& out);
  static bool tryGetExactSignedInt64FromScalar(const EvalValue::ScalarValue& s, long long& outI);
  static bool tryGetSignedInt64FromScalar(const EvalValue::ScalarValue& s, long long& outI);
  static bool isPureFloatingScalarPair(const EvalValue::ScalarValue& a, const EvalValue::ScalarValue& b);

  static std::string formatScalar(const EvalValue& v, RenderBase base);
  static std::string valueToString(const EvalValue& v, RenderBase forcedBase);
  static std::string valueToString(const EvalValue& v);
  static const std::vector<std::string>& functionNames();
  static const std::unordered_map<std::string, BuiltinFunctionId>& functionNameToId();
  static const std::vector<std::string>& operatorNames();
  static const std::string& getFunctionName(BuiltinFunctionId id);
  static const std::string& opName(OperatorNameId id);
  static bool tryGetBuiltinFunctionId(const std::string& nameText, BuiltinFunctionId& outId);
  static const char* tryGetBuiltinFunctionMissingCallHint(const std::string& nameText);
  static bool isOpKeyword(const std::string& nameText, OperatorNameId id);
  static bool isReservedFunctionName(const std::string& nameText);
  static bool isTrailingFormatterFunctionName(const std::string& nameText);
  bool trySetMissingFunctionCallError(EvalContext& ctx, const std::string& ident) const;
  bool handleUnknownIdentifier(EvalContext& ctx, const std::string& ident, std::string& unknownList) const;
  bool tryResolveVariableValue(
      const Expr& e,
      const std::unordered_map<std::string, EvalValue>* scopedVars,
      EvalValue& out) const;

  void setError(EvalContext& ctx, const std::string& msg) const;

  bool parseProgram(EvalContext& ctx, std::vector<AstStatement>& out);
  std::unique_ptr<Expr> parseExpression(EvalContext& ctx);
  std::unique_ptr<Expr> parseOr(EvalContext& ctx);
  std::unique_ptr<Expr> parseAnd(EvalContext& ctx);
  std::unique_ptr<Expr> parseLogicalNot(EvalContext& ctx);
  std::unique_ptr<Expr> parseCompare(EvalContext& ctx);
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
  static bool exprContainsPostfixPercent(const Expr& e);
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
      std::vector<EvalValue> args,
      BuiltinFunctionId preboundId,
      const std::unordered_map<std::string, EvalValue>* scopedVars);

  bool flattenRequired(
      EvalContext& ctx,
      const std::string& fnName,
      const std::vector<EvalValue>& args,
      std::vector<double>& flat) const;

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
  EvalValue builtinDegRad(
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
  EvalValue builtinApplyLogWithBase(EvalContext& ctx, const EvalValue& valueV, const EvalValue& baseV) const;
  EvalValue builtinApplyClamp(EvalContext& ctx, const EvalValue& valueV, const EvalValue& minV, const EvalValue& maxV) const;
  EvalValue evalUserFunctionCall(
      EvalContext& ctx,
      const std::string& fnName,
      const std::vector<EvalValue>& args,
      const std::unordered_map<std::string, EvalValue>* scopedVars);

  bool parseFunctionDefinition(
      EvalContext& ctx,
      std::string& outName,
      std::vector<std::string>& outParams,
      std::string& outExpr) const;

  static bool flattenArgs(const std::vector<EvalValue>& args, std::vector<double>& out);
  static std::size_t countFlattenedScalars(const std::vector<EvalValue>& args);
  static int expandUnpackedArgs(const std::vector<EvalValue>& in, std::vector<EvalValue>& out);
  void setVariable(const std::string& name, const EvalValue& value);
  void normalizeCallArgs(std::vector<EvalValue>& args);
  void bindExprVariableRefs(Expr& e);
  void bindCompiledVariableRefs();

  static EvalValue makeScalar(double v);
  static EvalValue makeScalarMaybeExact(double v);
  static EvalValue makeScalarInt(long long v);
  static EvalValue makeScalarUInt(std::uint64_t v);
  static EvalValue makeArray(const std::vector<double>& v);
  static EvalValue makeArrayFromScalars(const std::vector<EvalValue>& v);
  static RawResult::Scalar toRawScalar(const EvalValue::ScalarValue& v);
  static RawResult toRawResult(const EvalValue& v);
  static EvalValue scalarFromArrayAt(const EvalValue& arrV, std::size_t idx);
  EvalValue makeBinaryNumericError(
      EvalContext& ctx,
      const EvalValue& left,
      const EvalValue& right,
      const char* numericErrorText);
  static bool applyBinary(double a, double b, char op, double& out);
  static EvalValue mapUnaryFn(const EvalValue& in, double (*fn)(double));
  /** Unary minus with exact int/uint preservation; LLONG_MIN -> double. */
  static EvalValue negateEvalValue(const EvalValue& v);
  EvalValue mapBinary(const EvalValue& a, const EvalValue& b, char op, bool& ok) const;
  UserFunction* findUserFunction(const std::string& fnName);
  const UserFunction* findUserFunction(const std::string& fnName) const;
  void upsertUserFunction(UserFunction uf);
};
