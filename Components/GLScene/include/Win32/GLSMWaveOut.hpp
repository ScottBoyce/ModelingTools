﻿// CodeGear C++Builder
// Copyright (c) 1995, 2022 by Embarcadero Technologies, Inc.
// All rights reserved

// (DO NOT EDIT: machine generated header) 'GLSMWaveOut.pas' rev: 35.00 (Windows)

#ifndef GlsmwaveoutHPP
#define GlsmwaveoutHPP

#pragma delphiheader begin
#pragma option push
#pragma option -w-      // All warnings off
#pragma option -Vx      // Zero-length empty class member 
#pragma pack(push,8)
#include <System.hpp>
#include <SysInit.hpp>
#include <Winapi.MMSystem.hpp>
#include <System.Classes.hpp>
#include <System.SysUtils.hpp>
#include <GLSound.hpp>
#include <GLSoundFileObjects.hpp>

//-- user supplied -----------------------------------------------------------

namespace Glsmwaveout
{
//-- forward type declarations -----------------------------------------------
class DELPHICLASS TGLSMWaveOut;
//-- type declarations -------------------------------------------------------
class PASCALIMPLEMENTATION TGLSMWaveOut : public Glsound::TGLSoundManager
{
	typedef Glsound::TGLSoundManager inherited;
	
protected:
	virtual bool __fastcall DoActivate();
	virtual void __fastcall DoDeActivate();
	virtual void __fastcall KillSource(Glsound::TGLBaseSoundSource* aSource);
	
public:
	__fastcall virtual TGLSMWaveOut(System::Classes::TComponent* AOwner);
	__fastcall virtual ~TGLSMWaveOut();
	virtual void __fastcall UpdateSources();
	
__published:
	__property MaxChannels = {default=4};
};


//-- var, const, procedure ---------------------------------------------------
extern DELPHI_PACKAGE NativeInt __fastcall PlayOnWaveOut(void * pcmData, int lengthInBytes, const tWAVEFORMATEX &waveFormat)/* overload */;
extern DELPHI_PACKAGE void __fastcall PlayOnWaveOut(void * pcmData, int lengthInBytes, Glsoundfileobjects::TGLSoundSampling* sampling)/* overload */;
}	/* namespace Glsmwaveout */
#if !defined(DELPHIHEADER_NO_IMPLICIT_NAMESPACE_USE) && !defined(NO_USING_NAMESPACE_GLSMWAVEOUT)
using namespace Glsmwaveout;
#endif
#pragma pack(pop)
#pragma option pop

#pragma delphiheader end.
//-- end unit ----------------------------------------------------------------
#endif	// GlsmwaveoutHPP