﻿// CodeGear C++Builder
// Copyright (c) 1995, 2022 by Embarcadero Technologies, Inc.
// All rights reserved

// (DO NOT EDIT: machine generated header) 'GR32_Transforms.pas' rev: 35.00 (Windows)

#ifndef Gr32_transformsHPP
#define Gr32_transformsHPP

#pragma delphiheader begin
#pragma option push
#pragma option -w-      // All warnings off
#pragma option -Vx      // Zero-length empty class member 
#pragma pack(push,8)
#include <System.hpp>
#include <SysInit.hpp>
#include <Winapi.Windows.hpp>
#include <System.SysUtils.hpp>
#include <System.Classes.hpp>
#include <GR32.hpp>
#include <GR32_Blend.hpp>
#include <GR32_VectorMaps.hpp>
#include <GR32_Rasterizers.hpp>
#include <System.Types.hpp>

//-- user supplied -----------------------------------------------------------

namespace Gr32_transforms
{
//-- forward type declarations -----------------------------------------------
class DELPHICLASS ETransformError;
class DELPHICLASS ETransformNotImplemented;
class DELPHICLASS TTransformation;
class DELPHICLASS TAffineTransformation;
class DELPHICLASS TProjectiveTransformation;
class DELPHICLASS TTwirlTransformation;
class DELPHICLASS TBloatTransformation;
class DELPHICLASS TDisturbanceTransformation;
class DELPHICLASS TFishEyeTransformation;
class DELPHICLASS TPolarTransformation;
class DELPHICLASS TPathTransformation;
class DELPHICLASS TRemapTransformation;
//-- type declarations -------------------------------------------------------
#pragma pack(push,4)
class PASCALIMPLEMENTATION ETransformError : public System::Sysutils::Exception
{
	typedef System::Sysutils::Exception inherited;
	
public:
	/* Exception.Create */ inline __fastcall ETransformError(const System::UnicodeString Msg) : System::Sysutils::Exception(Msg) { }
	/* Exception.CreateFmt */ inline __fastcall ETransformError(const System::UnicodeString Msg, const System::TVarRec *Args, const int Args_High) : System::Sysutils::Exception(Msg, Args, Args_High) { }
	/* Exception.CreateRes */ inline __fastcall ETransformError(NativeUInt Ident)/* overload */ : System::Sysutils::Exception(Ident) { }
	/* Exception.CreateRes */ inline __fastcall ETransformError(System::PResStringRec ResStringRec)/* overload */ : System::Sysutils::Exception(ResStringRec) { }
	/* Exception.CreateResFmt */ inline __fastcall ETransformError(NativeUInt Ident, const System::TVarRec *Args, const int Args_High)/* overload */ : System::Sysutils::Exception(Ident, Args, Args_High) { }
	/* Exception.CreateResFmt */ inline __fastcall ETransformError(System::PResStringRec ResStringRec, const System::TVarRec *Args, const int Args_High)/* overload */ : System::Sysutils::Exception(ResStringRec, Args, Args_High) { }
	/* Exception.CreateHelp */ inline __fastcall ETransformError(const System::UnicodeString Msg, int AHelpContext) : System::Sysutils::Exception(Msg, AHelpContext) { }
	/* Exception.CreateFmtHelp */ inline __fastcall ETransformError(const System::UnicodeString Msg, const System::TVarRec *Args, const int Args_High, int AHelpContext) : System::Sysutils::Exception(Msg, Args, Args_High, AHelpContext) { }
	/* Exception.CreateResHelp */ inline __fastcall ETransformError(NativeUInt Ident, int AHelpContext)/* overload */ : System::Sysutils::Exception(Ident, AHelpContext) { }
	/* Exception.CreateResHelp */ inline __fastcall ETransformError(System::PResStringRec ResStringRec, int AHelpContext)/* overload */ : System::Sysutils::Exception(ResStringRec, AHelpContext) { }
	/* Exception.CreateResFmtHelp */ inline __fastcall ETransformError(System::PResStringRec ResStringRec, const System::TVarRec *Args, const int Args_High, int AHelpContext)/* overload */ : System::Sysutils::Exception(ResStringRec, Args, Args_High, AHelpContext) { }
	/* Exception.CreateResFmtHelp */ inline __fastcall ETransformError(NativeUInt Ident, const System::TVarRec *Args, const int Args_High, int AHelpContext)/* overload */ : System::Sysutils::Exception(Ident, Args, Args_High, AHelpContext) { }
	/* Exception.Destroy */ inline __fastcall virtual ~ETransformError() { }
	
};

#pragma pack(pop)

#pragma pack(push,4)
class PASCALIMPLEMENTATION ETransformNotImplemented : public System::Sysutils::Exception
{
	typedef System::Sysutils::Exception inherited;
	
public:
	/* Exception.Create */ inline __fastcall ETransformNotImplemented(const System::UnicodeString Msg) : System::Sysutils::Exception(Msg) { }
	/* Exception.CreateFmt */ inline __fastcall ETransformNotImplemented(const System::UnicodeString Msg, const System::TVarRec *Args, const int Args_High) : System::Sysutils::Exception(Msg, Args, Args_High) { }
	/* Exception.CreateRes */ inline __fastcall ETransformNotImplemented(NativeUInt Ident)/* overload */ : System::Sysutils::Exception(Ident) { }
	/* Exception.CreateRes */ inline __fastcall ETransformNotImplemented(System::PResStringRec ResStringRec)/* overload */ : System::Sysutils::Exception(ResStringRec) { }
	/* Exception.CreateResFmt */ inline __fastcall ETransformNotImplemented(NativeUInt Ident, const System::TVarRec *Args, const int Args_High)/* overload */ : System::Sysutils::Exception(Ident, Args, Args_High) { }
	/* Exception.CreateResFmt */ inline __fastcall ETransformNotImplemented(System::PResStringRec ResStringRec, const System::TVarRec *Args, const int Args_High)/* overload */ : System::Sysutils::Exception(ResStringRec, Args, Args_High) { }
	/* Exception.CreateHelp */ inline __fastcall ETransformNotImplemented(const System::UnicodeString Msg, int AHelpContext) : System::Sysutils::Exception(Msg, AHelpContext) { }
	/* Exception.CreateFmtHelp */ inline __fastcall ETransformNotImplemented(const System::UnicodeString Msg, const System::TVarRec *Args, const int Args_High, int AHelpContext) : System::Sysutils::Exception(Msg, Args, Args_High, AHelpContext) { }
	/* Exception.CreateResHelp */ inline __fastcall ETransformNotImplemented(NativeUInt Ident, int AHelpContext)/* overload */ : System::Sysutils::Exception(Ident, AHelpContext) { }
	/* Exception.CreateResHelp */ inline __fastcall ETransformNotImplemented(System::PResStringRec ResStringRec, int AHelpContext)/* overload */ : System::Sysutils::Exception(ResStringRec, AHelpContext) { }
	/* Exception.CreateResFmtHelp */ inline __fastcall ETransformNotImplemented(System::PResStringRec ResStringRec, const System::TVarRec *Args, const int Args_High, int AHelpContext)/* overload */ : System::Sysutils::Exception(ResStringRec, Args, Args_High, AHelpContext) { }
	/* Exception.CreateResFmtHelp */ inline __fastcall ETransformNotImplemented(NativeUInt Ident, const System::TVarRec *Args, const int Args_High, int AHelpContext)/* overload */ : System::Sysutils::Exception(Ident, Args, Args_High, AHelpContext) { }
	/* Exception.Destroy */ inline __fastcall virtual ~ETransformNotImplemented() { }
	
};

#pragma pack(pop)

typedef System::StaticArray<System::StaticArray<float, 3>, 3> TFloatMatrix;

typedef System::StaticArray<System::StaticArray<Gr32::TFixed, 3>, 3> TFixedMatrix;

typedef System::StaticArray<float, 3> TVector3f;

typedef System::StaticArray<int, 3> TVector3i;

class PASCALIMPLEMENTATION TTransformation : public Gr32::TNotifiablePersistent
{
	typedef Gr32::TNotifiablePersistent inherited;
	
private:
	Gr32::TFloatRect FSrcRect;
	void __fastcall SetSrcRect(const Gr32::TFloatRect &Value);
	
protected:
	bool TransformValid;
	virtual void __fastcall PrepareTransform();
	virtual void __fastcall ReverseTransformInt(int DstX, int DstY, /* out */ int &SrcX, /* out */ int &SrcY);
	virtual void __fastcall ReverseTransformFixed(Gr32::TFixed DstX, Gr32::TFixed DstY, /* out */ Gr32::TFixed &SrcX, /* out */ Gr32::TFixed &SrcY);
	virtual void __fastcall ReverseTransformFloat(float DstX, float DstY, /* out */ float &SrcX, /* out */ float &SrcY);
	virtual void __fastcall TransformInt(int SrcX, int SrcY, /* out */ int &DstX, /* out */ int &DstY);
	virtual void __fastcall TransformFixed(Gr32::TFixed SrcX, Gr32::TFixed SrcY, /* out */ Gr32::TFixed &DstX, /* out */ Gr32::TFixed &DstY);
	virtual void __fastcall TransformFloat(float SrcX, float SrcY, /* out */ float &DstX, /* out */ float &DstY);
	
public:
	virtual void __fastcall Changed();
	virtual bool __fastcall HasTransformedBounds();
	Gr32::TFloatRect __fastcall GetTransformedBounds()/* overload */;
	virtual Gr32::TFloatRect __fastcall GetTransformedBounds(const Gr32::TFloatRect &ASrcRect)/* overload */;
	virtual System::Types::TPoint __fastcall ReverseTransform(const System::Types::TPoint &P)/* overload */;
	virtual Gr32::TFixedPoint __fastcall ReverseTransform(const Gr32::TFixedPoint &P)/* overload */;
	virtual Gr32::TFloatPoint __fastcall ReverseTransform(const Gr32::TFloatPoint &P)/* overload */;
	virtual System::Types::TPoint __fastcall Transform(const System::Types::TPoint &P)/* overload */;
	virtual Gr32::TFixedPoint __fastcall Transform(const Gr32::TFixedPoint &P)/* overload */;
	virtual Gr32::TFloatPoint __fastcall Transform(const Gr32::TFloatPoint &P)/* overload */;
	__property Gr32::TFloatRect SrcRect = {read=FSrcRect, write=SetSrcRect};
public:
	/* TPersistent.Destroy */ inline __fastcall virtual ~TTransformation() { }
	
public:
	/* TObject.Create */ inline __fastcall TTransformation() : Gr32::TNotifiablePersistent() { }
	
};


class PASCALIMPLEMENTATION TAffineTransformation : public TTransformation
{
	typedef TTransformation inherited;
	
protected:
	TFloatMatrix FInverseMatrix;
	TFixedMatrix FFixedMatrix;
	TFixedMatrix FInverseFixedMatrix;
	virtual void __fastcall PrepareTransform();
	virtual void __fastcall ReverseTransformFloat(float DstX, float DstY, /* out */ float &SrcX, /* out */ float &SrcY);
	virtual void __fastcall ReverseTransformFixed(Gr32::TFixed DstX, Gr32::TFixed DstY, /* out */ Gr32::TFixed &SrcX, /* out */ Gr32::TFixed &SrcY);
	virtual void __fastcall TransformFloat(float SrcX, float SrcY, /* out */ float &DstX, /* out */ float &DstY);
	virtual void __fastcall TransformFixed(Gr32::TFixed SrcX, Gr32::TFixed SrcY, /* out */ Gr32::TFixed &DstX, /* out */ Gr32::TFixed &DstY);
	
public:
	TFloatMatrix Matrix;
	__fastcall virtual TAffineTransformation();
	virtual Gr32::TFloatRect __fastcall GetTransformedBounds(const Gr32::TFloatRect &ASrcRect)/* overload */;
	void __fastcall Clear();
	void __fastcall Rotate(float Alpha)/* overload */;
	void __fastcall Rotate(float Cx, float Cy, float Alpha)/* overload */;
	void __fastcall Skew(float Fx, float Fy);
	void __fastcall Scale(float Sx, float Sy)/* overload */;
	void __fastcall Scale(float Value)/* overload */;
	void __fastcall Translate(float Dx, float Dy);
public:
	/* TPersistent.Destroy */ inline __fastcall virtual ~TAffineTransformation() { }
	
	/* Hoisted overloads: */
	
public:
	inline Gr32::TFloatRect __fastcall  GetTransformedBounds(){ return TTransformation::GetTransformedBounds(); }
	
};


class PASCALIMPLEMENTATION TProjectiveTransformation : public TTransformation
{
	typedef TTransformation inherited;
	
private:
	float Wx0;
	float Wx1;
	float Wx2;
	float Wx3;
	float Wy0;
	float Wy1;
	float Wy2;
	float Wy3;
	void __fastcall SetX0(float Value);
	void __fastcall SetX1(float Value);
	void __fastcall SetX2(float Value);
	void __fastcall SetX3(float Value);
	void __fastcall SetY0(float Value);
	void __fastcall SetY1(float Value);
	void __fastcall SetY2(float Value);
	void __fastcall SetY3(float Value);
	
protected:
	TFloatMatrix FMatrix;
	TFloatMatrix FInverseMatrix;
	TFixedMatrix FFixedMatrix;
	TFixedMatrix FInverseFixedMatrix;
	virtual void __fastcall PrepareTransform();
	virtual void __fastcall ReverseTransformFloat(float DstX, float DstY, /* out */ float &SrcX, /* out */ float &SrcY);
	virtual void __fastcall ReverseTransformFixed(Gr32::TFixed DstX, Gr32::TFixed DstY, /* out */ Gr32::TFixed &SrcX, /* out */ Gr32::TFixed &SrcY);
	virtual void __fastcall TransformFloat(float SrcX, float SrcY, /* out */ float &DstX, /* out */ float &DstY);
	virtual void __fastcall TransformFixed(Gr32::TFixed SrcX, Gr32::TFixed SrcY, /* out */ Gr32::TFixed &DstX, /* out */ Gr32::TFixed &DstY);
	
public:
	virtual Gr32::TFloatRect __fastcall GetTransformedBounds(const Gr32::TFloatRect &ASrcRect)/* overload */;
	
__published:
	__property float X0 = {read=Wx0, write=SetX0};
	__property float X1 = {read=Wx1, write=SetX1};
	__property float X2 = {read=Wx2, write=SetX2};
	__property float X3 = {read=Wx3, write=SetX3};
	__property float Y0 = {read=Wy0, write=SetY0};
	__property float Y1 = {read=Wy1, write=SetY1};
	__property float Y2 = {read=Wy2, write=SetY2};
	__property float Y3 = {read=Wy3, write=SetY3};
public:
	/* TPersistent.Destroy */ inline __fastcall virtual ~TProjectiveTransformation() { }
	
public:
	/* TObject.Create */ inline __fastcall TProjectiveTransformation() : TTransformation() { }
	
	/* Hoisted overloads: */
	
public:
	inline Gr32::TFloatRect __fastcall  GetTransformedBounds(){ return TTransformation::GetTransformedBounds(); }
	
};


class PASCALIMPLEMENTATION TTwirlTransformation : public TTransformation
{
	typedef TTransformation inherited;
	
private:
	float Frx;
	float Fry;
	float FTwirl;
	void __fastcall SetTwirl(const float Value);
	
protected:
	virtual void __fastcall PrepareTransform();
	virtual void __fastcall ReverseTransformFloat(float DstX, float DstY, /* out */ float &SrcX, /* out */ float &SrcY);
	
public:
	__fastcall virtual TTwirlTransformation();
	virtual Gr32::TFloatRect __fastcall GetTransformedBounds(const Gr32::TFloatRect &ASrcRect)/* overload */;
	
__published:
	__property float Twirl = {read=FTwirl, write=SetTwirl};
public:
	/* TPersistent.Destroy */ inline __fastcall virtual ~TTwirlTransformation() { }
	
	/* Hoisted overloads: */
	
public:
	inline Gr32::TFloatRect __fastcall  GetTransformedBounds(){ return TTransformation::GetTransformedBounds(); }
	
};


class PASCALIMPLEMENTATION TBloatTransformation : public TTransformation
{
	typedef TTransformation inherited;
	
private:
	float FBloatPower;
	float FBP;
	float FPiW;
	float FPiH;
	void __fastcall SetBloatPower(const float Value);
	
protected:
	virtual void __fastcall PrepareTransform();
	virtual void __fastcall ReverseTransformFloat(float DstX, float DstY, /* out */ float &SrcX, /* out */ float &SrcY);
	
public:
	__fastcall virtual TBloatTransformation();
	
__published:
	__property float BloatPower = {read=FBloatPower, write=SetBloatPower};
public:
	/* TPersistent.Destroy */ inline __fastcall virtual ~TBloatTransformation() { }
	
};


class PASCALIMPLEMENTATION TDisturbanceTransformation : public TTransformation
{
	typedef TTransformation inherited;
	
private:
	float FDisturbance;
	void __fastcall SetDisturbance(const float Value);
	
protected:
	virtual void __fastcall ReverseTransformFloat(float DstX, float DstY, /* out */ float &SrcX, /* out */ float &SrcY);
	
public:
	virtual Gr32::TFloatRect __fastcall GetTransformedBounds(const Gr32::TFloatRect &ASrcRect)/* overload */;
	
__published:
	__property float Disturbance = {read=FDisturbance, write=SetDisturbance};
public:
	/* TPersistent.Destroy */ inline __fastcall virtual ~TDisturbanceTransformation() { }
	
public:
	/* TObject.Create */ inline __fastcall TDisturbanceTransformation() : TTransformation() { }
	
	/* Hoisted overloads: */
	
public:
	inline Gr32::TFloatRect __fastcall  GetTransformedBounds(){ return TTransformation::GetTransformedBounds(); }
	
};


class PASCALIMPLEMENTATION TFishEyeTransformation : public TTransformation
{
	typedef TTransformation inherited;
	
private:
	float Frx;
	float Fry;
	float Faw;
	float Fsr;
	float Sx;
	float Sy;
	float FMinR;
	
protected:
	virtual void __fastcall PrepareTransform();
	virtual void __fastcall ReverseTransformFloat(float DstX, float DstY, /* out */ float &SrcX, /* out */ float &SrcY);
public:
	/* TPersistent.Destroy */ inline __fastcall virtual ~TFishEyeTransformation() { }
	
public:
	/* TObject.Create */ inline __fastcall TFishEyeTransformation() : TTransformation() { }
	
};


class PASCALIMPLEMENTATION TPolarTransformation : public TTransformation
{
	typedef TTransformation inherited;
	
private:
	Gr32::TFloatRect FDstRect;
	float FPhase;
	float Sx;
	float Sy;
	float Cx;
	float Cy;
	float Dx;
	float Dy;
	float Rt;
	float Rt2;
	float Rr;
	float Rcx;
	float Rcy;
	void __fastcall SetDstRect(const Gr32::TFloatRect &Value);
	void __fastcall SetPhase(const float Value);
	
protected:
	virtual void __fastcall PrepareTransform();
	virtual void __fastcall TransformFloat(float SrcX, float SrcY, /* out */ float &DstX, /* out */ float &DstY);
	virtual void __fastcall ReverseTransformFloat(float DstX, float DstY, /* out */ float &SrcX, /* out */ float &SrcY);
	
public:
	__property Gr32::TFloatRect DstRect = {read=FDstRect, write=SetDstRect};
	__property float Phase = {read=FPhase, write=SetPhase};
public:
	/* TPersistent.Destroy */ inline __fastcall virtual ~TPolarTransformation() { }
	
public:
	/* TObject.Create */ inline __fastcall TPolarTransformation() : TTransformation() { }
	
};


class PASCALIMPLEMENTATION TPathTransformation : public TTransformation
{
	typedef TTransformation inherited;
	
	
private:
	struct DECLSPEC_DRECORD _TPathTransformation__1
	{
	public:
		float Dist;
		float RecDist;
	};
	
	
	typedef System::DynamicArray<_TPathTransformation__1> _TPathTransformation__2;
	
	
private:
	float FTopLength;
	float FBottomLength;
	Gr32::TArrayOfFloatPoint FBottomCurve;
	Gr32::TArrayOfFloatPoint FTopCurve;
	_TPathTransformation__2 FTopHypot;
	_TPathTransformation__2 FBottomHypot;
	void __fastcall SetBottomCurve(const Gr32::TArrayOfFloatPoint Value);
	void __fastcall SetTopCurve(const Gr32::TArrayOfFloatPoint Value);
	
protected:
	float rdx;
	float rdy;
	virtual void __fastcall PrepareTransform();
	virtual void __fastcall TransformFloat(float SrcX, float SrcY, /* out */ float &DstX, /* out */ float &DstY);
	
public:
	__fastcall virtual ~TPathTransformation();
	__property Gr32::TArrayOfFloatPoint TopCurve = {read=FTopCurve, write=SetTopCurve};
	__property Gr32::TArrayOfFloatPoint BottomCurve = {read=FBottomCurve, write=SetBottomCurve};
public:
	/* TObject.Create */ inline __fastcall TPathTransformation() : TTransformation() { }
	
};


class PASCALIMPLEMENTATION TRemapTransformation : public TTransformation
{
	typedef TTransformation inherited;
	
private:
	Gr32_vectormaps::TVectorMap* FVectorMap;
	Gr32::TFixedPoint FScalingFixed;
	Gr32::TFloatPoint FScalingFloat;
	Gr32::TFixedPoint FCombinedScalingFixed;
	Gr32::TFloatPoint FCombinedScalingFloat;
	Gr32::TFixedPoint FSrcTranslationFixed;
	Gr32::TFixedPoint FSrcScaleFixed;
	Gr32::TFixedPoint FDstTranslationFixed;
	Gr32::TFixedPoint FDstScaleFixed;
	Gr32::TFloatPoint FSrcTranslationFloat;
	Gr32::TFloatPoint FSrcScaleFloat;
	Gr32::TFloatPoint FDstTranslationFloat;
	Gr32::TFloatPoint FDstScaleFloat;
	Gr32::TFixedPoint FOffsetFixed;
	System::Types::TPoint FOffsetInt;
	Gr32::TFloatRect FMappingRect;
	Gr32::TFloatPoint FOffset;
	void __fastcall SetMappingRect(const Gr32::TFloatRect &Rect);
	void __fastcall SetOffset(const Gr32::TFloatPoint &Value);
	
protected:
	virtual void __fastcall PrepareTransform();
	virtual void __fastcall ReverseTransformInt(int DstX, int DstY, /* out */ int &SrcX, /* out */ int &SrcY);
	virtual void __fastcall ReverseTransformFloat(float DstX, float DstY, /* out */ float &SrcX, /* out */ float &SrcY);
	virtual void __fastcall ReverseTransformFixed(Gr32::TFixed DstX, Gr32::TFixed DstY, /* out */ Gr32::TFixed &SrcX, /* out */ Gr32::TFixed &SrcY);
	
public:
	__fastcall virtual TRemapTransformation();
	__fastcall virtual ~TRemapTransformation();
	virtual bool __fastcall HasTransformedBounds();
	virtual Gr32::TFloatRect __fastcall GetTransformedBounds(const Gr32::TFloatRect &ASrcRect)/* overload */;
	void __fastcall Scale(float Sx, float Sy);
	__property Gr32::TFloatRect MappingRect = {read=FMappingRect, write=SetMappingRect};
	__property Gr32::TFloatPoint Offset = {read=FOffset, write=SetOffset};
	__property Gr32_vectormaps::TVectorMap* VectorMap = {read=FVectorMap, write=FVectorMap};
	/* Hoisted overloads: */
	
public:
	inline Gr32::TFloatRect __fastcall  GetTransformedBounds(){ return TTransformation::GetTransformedBounds(); }
	
};


//-- var, const, procedure ---------------------------------------------------
extern DELPHI_PACKAGE TFloatMatrix IdentityMatrix;
extern DELPHI_PACKAGE bool FullEdge;
extern DELPHI_PACKAGE System::ResourceString _RCStrReverseTransformationNotImplemented;
#define Gr32_transforms_RCStrReverseTransformationNotImplemented System::LoadResourceString(&Gr32_transforms::_RCStrReverseTransformationNotImplemented)
extern DELPHI_PACKAGE System::ResourceString _RCStrForwardTransformationNotImplemented;
#define Gr32_transforms_RCStrForwardTransformationNotImplemented System::LoadResourceString(&Gr32_transforms::_RCStrForwardTransformationNotImplemented)
extern DELPHI_PACKAGE System::ResourceString _RCStrTopBottomCurveNil;
#define Gr32_transforms_RCStrTopBottomCurveNil System::LoadResourceString(&Gr32_transforms::_RCStrTopBottomCurveNil)
extern DELPHI_PACKAGE void __fastcall Adjoint(TFloatMatrix &M);
extern DELPHI_PACKAGE float __fastcall Determinant(const TFloatMatrix &M);
extern DELPHI_PACKAGE void __fastcall Scale(TFloatMatrix &M, float Factor);
extern DELPHI_PACKAGE void __fastcall Invert(TFloatMatrix &M);
extern DELPHI_PACKAGE TFloatMatrix __fastcall Mult(const TFloatMatrix &M1, const TFloatMatrix &M2);
extern DELPHI_PACKAGE TVector3f __fastcall VectorTransform(const TFloatMatrix &M, const TVector3f &V);
extern DELPHI_PACKAGE Gr32::TArrayOfArrayOfFixedPoint __fastcall TransformPoints(Gr32::TArrayOfArrayOfFixedPoint Points, TTransformation* Transformation);
extern DELPHI_PACKAGE void __fastcall Transform(Gr32::TCustomBitmap32* Dst, Gr32::TCustomBitmap32* Src, TTransformation* Transformation)/* overload */;
extern DELPHI_PACKAGE void __fastcall Transform(Gr32::TCustomBitmap32* Dst, Gr32::TCustomBitmap32* Src, TTransformation* Transformation, const System::Types::TRect &DstClip)/* overload */;
extern DELPHI_PACKAGE void __fastcall Transform(Gr32::TCustomBitmap32* Dst, Gr32::TCustomBitmap32* Src, TTransformation* Transformation, Gr32_rasterizers::TRasterizer* Rasterizer)/* overload */;
extern DELPHI_PACKAGE void __fastcall Transform(Gr32::TCustomBitmap32* Dst, Gr32::TCustomBitmap32* Src, TTransformation* Transformation, Gr32_rasterizers::TRasterizer* Rasterizer, const System::Types::TRect &DstClip)/* overload */;
extern DELPHI_PACKAGE void __fastcall SetBorderTransparent(Gr32::TCustomBitmap32* ABitmap, const System::Types::TRect &ARect);
extern DELPHI_PACKAGE void __fastcall RasterizeTransformation(Gr32_vectormaps::TVectorMap* Vectormap, TTransformation* Transformation, const System::Types::TRect &DstRect, Gr32_vectormaps::TVectorCombineMode CombineMode = (Gr32_vectormaps::TVectorCombineMode)(0x0), Gr32_vectormaps::TVectorCombineEvent CombineCallback = 0x0);
extern DELPHI_PACKAGE TFixedMatrix __fastcall FixedMatrix(const TFloatMatrix &FloatMatrix)/* overload */;
extern DELPHI_PACKAGE TFloatMatrix __fastcall FloatMatrix(const TFixedMatrix &FixedMatrix)/* overload */;
}	/* namespace Gr32_transforms */
#if !defined(DELPHIHEADER_NO_IMPLICIT_NAMESPACE_USE) && !defined(NO_USING_NAMESPACE_GR32_TRANSFORMS)
using namespace Gr32_transforms;
#endif
#pragma pack(pop)
#pragma option pop

#pragma delphiheader end.
//-- end unit ----------------------------------------------------------------
#endif	// Gr32_transformsHPP