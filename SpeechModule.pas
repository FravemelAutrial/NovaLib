unit SpeechModule;

interface

uses
  Windows, Classes, ExtCtrls, Speech, ActiveX, ComObj, SysUtils;

type
  TSpeechUnit = class(TObject)
  private
    MessageQueue: TStringList;
    SpeechTimer: TTimer;
    // ����������� ���������, ����� ������� ������������ ��� �������� � �����}
    fITTSCentral: ITTSCentral;
    // ��������� ��� ����� � ����������������
    fIAMM: IAudioMultimediaDevice;
    // ��������� ��� �������� �������
    aTTSEnum: ITTSEnum;
    // ��������� �� ��������� ������
    fpModeInfo: PTTSModeInfo;
    // ������ �������
    VoicesList: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SelectVoiceEngine(EngineIndex: Integer);
    function GetVoicesList: TStringList;
    procedure SpeechText(const AText: string);
    procedure AddSpeechText(const AText: string);
  published
    procedure SpeechTextFromQueue(Sender: TObject);
  end;

{ ���������� ��������� ������������� �������, ��������: "���� ����� ���� �����" }
function GetTimeString(ATime: TDateTime): string;

implementation

function GetTimeString(ATime: TDateTime): string;
var
  Hour, Min, Sec, MSec: Word;
begin
  DecodeTime(ATime, Hour, Min, Sec, MSec);
  case Hour of
    0: Result := '���� ����� ';
    1: Result := '���� ��� ';
    2: Result := '��� ���� ';
    3: Result := '��� ���� ';
    4: Result := '������ ���� ';
    5: Result := '���� ����� ';
    6: Result := '����� ����� ';
    7: Result := '���� ����� ';
    8: Result := '������ ����� ';
    9: Result := '������ ����� ';
    10: Result := '������ ����� ';
    11: Result := '����������� ����� ';
    12: Result := '���������� ����� ';
    13: Result := '���������� ����� ';
    14: Result := '������������ ����� ';
    15: Result := '���������� ����� ';
    16: Result := '����������� ����� ';
    17: Result := '���������� ����� ';
    18: Result := '������������ ����� ';
    19: Result := '������������ ����� ';
    20: Result := '�������� ����� ';
    21: Result := '�������� ���� ��� ';
    22: Result := '�������� ��� ���� ';
    23: Result := '�������� ��� ���� ';
  end;

  case Min of
    0: Result := Result + '���� �����';
    1: Result := Result + '���� ������';
    2: Result := Result + '��� ������';
    3: Result := Result + '��� ������';
    4: Result := Result + '������ ������';
    5: Result := Result + '���� �����';
    6: Result := Result + '����� �����';
    7: Result := Result + '���� �����';
    8: Result := Result + '������ �����';
    9: Result := Result + '������ �����';
    10: Result := Result + '������ �����';
    11: Result := Result + '����������� �����';
    12: Result := Result + '���������� �����';
    13: Result := Result + '���������� �����';
    14: Result := Result + '������������ �����';
    15: Result := Result + '���������� �����';
    16: Result := Result + '����������� �����';
    17: Result := Result + '���������� �����';
    18: Result := Result + '������������ �����';
    19: Result := Result + '������������ �����';
    20: Result := Result + '�������� �����';
    21: Result := Result + '�������� ���� ������';
    22: Result := Result + '�������� ��� ������';
    23: Result := Result + '�������� ��� ������';
    24: Result := Result + '�������� ������ ������';
    25: Result := Result + '�������� ���� �����';
    26: Result := Result + '�������� ����� �����';
    27: Result := Result + '�������� ���� �����';
    28: Result := Result + '�������� ������ �����';
    29: Result := Result + '�������� ������ �����';
    30: Result := Result + '�������� �����';
    31: Result := Result + '�������� ���� ������';
    32: Result := Result + '�������� ��� ������';
    33: Result := Result + '�������� ��� ������';
    34: Result := Result + '�������� ������ ������';
    35: Result := Result + '�������� ���� �����';
    36: Result := Result + '�������� ����� �����';
    37: Result := Result + '�������� ���� �����';
    38: Result := Result + '�������� ������ �����';
    39: Result := Result + '�������� ������ �����';
    40: Result := Result + '����� �����';
    41: Result := Result + '����� ���� ������';
    42: Result := Result + '����� ��� ������';
    43: Result := Result + '����� ��� ������';
    44: Result := Result + '����� ������ ������';
    45: Result := Result + '����� ���� �����';
    46: Result := Result + '����� ����� �����';
    47: Result := Result + '����� ���� �����';
    48: Result := Result + '����� ������ �����';
    49: Result := Result + '����� ������ �����';
    50: Result := Result + '��������� �����';
    51: Result := Result + '��������� ���� ������';
    52: Result := Result + '��������� ��� ������';
    53: Result := Result + '��������� ��� ������';
    54: Result := Result + '��������� ������ ������';
    55: Result := Result + '��������� ���� �����';
    56: Result := Result + '��������� ����� �����';
    57: Result := Result + '��������� ���� �����';
    58: Result := Result + '��������� ������ �����';
    59: Result := Result + '��������� ������ �����';
  end;
end;

constructor TSpeechUnit.Create();
var 
  NumFound : DWord;
  ModeInfo : TTSModeInfo;
  res: HRESULT;
begin
  inherited;

  SpeechTimer := TTimer.Create(nil);
  SpeechTimer.Interval := 500;
  SpeechTimer.OnTimer := SpeechTextFromQueue;
  MessageQueue := TStringList.Create;
  VoicesList := TStringList.Create;

  // ������������� ���������������
  res := CoCreateInstance(CLSID_MMAudioDest, nil, CLSCTX_ALL,  IID_IAudioMultiMediaDevice, fIAMM);
  if res = S_OK then
  begin
    // �������� �������������� ������� ��� �������� ���� ������� � ������� � ������� ���������� ITTSEnum
    res := CoCreateInstance(CLSID_TTSEnumerator, nil, CLSCTX_ALL, IID_ITTSEnum, aTTSEnum);
    if res = S_OK then
    begin
      // ���������� �� ������
      res := aTTSEnum.Reset();
      if res = S_OK then
      begin
        // �������� ������ ������
        res := aTTSEnum.Next(1, ModeInfo, @NumFound);
        while (res = S_OK) and (NumFound > 0) do
        begin
          VoicesList.Add(String(ModeInfo.szModeName));
          // �������� ���������
          res := aTTSEnum.Next(1, ModeInfo, @NumFound);
        end;
      end;
    end;
  end;


  if VoicesList.Count > 0 then
    SelectVoiceEngine(0);
end;

destructor TSpeechUnit.Destroy;
begin
  if Assigned(fpModeInfo) then
  begin
    Dispose(fpModeInfo);
  end;
  FreeAndNil(VoicesList);
  FreeAndNil(MessageQueue);
  FreeAndNil(SpeechTimer);
  inherited;
end;

procedure TSpeechUnit.SpeechTextFromQueue(Sender: TObject);
begin
  if MessageQueue.Count > 0 then
  begin
    SpeechText(MessageQueue.Strings[0]);
    MessageQueue.Delete(0);
  end;
end;

function TSpeechUnit.GetVoicesList: TStringList;
begin
  Result := VoicesList;
end;

procedure TSpeechUnit.SelectVoiceEngine(EngineIndex: Integer);
var
  NumFound: DWord;
  ModeInfo : TTSModeInfo;
  res: HRESULT;
begin
  if EngineIndex < 0 then
    Exit;

  res := CoCreateInstance(CLSID_MMAudioDest, nil, CLSCTX_ALL,  IID_IAudioMultiMediaDevice, fIAMM);
  if res = S_OK then
  begin
    res := CoCreateInstance(CLSID_TTSEnumerator, nil, CLSCTX_ALL, IID_ITTSEnum, aTTSEnum);
    if res = S_OK then
    begin
      res := aTTSEnum.Reset;
      if res = S_OK then
      begin
        res := aTTSEnum.skip(EngineIndex);
        if res = S_OK then
        begin
          res := aTTSEnum.Next(1, ModeInfo, @NumFound);
          if Assigned(fpModeInfo) then
          begin
            // ���� fpModeInfo �� ����� nil
            Dispose(fpModeInfo);
            fpModeInfo := nil;
          end;
          if (res = S_OK) then
          begin
            New(fpModeInfo);
            fpModeInfo^ := ModeInfo;
            // ��������� ������ �� ��� GUID
            aTTSEnum.Select(fpModeInfo^.gModeID, fITTSCentral, IUnknown(fIAMM));
          end;
        end;
      end;
    end;
  end;
end;

procedure TSpeechUnit.SpeechText(const AText: String);
var
  SData: TSData;
begin
  if Assigned(fITTSCentral) then
  begin
    SData.dwSize := Length(AText) + 1;
    SData.pData := PChar(AText);
    try
      fITTSCentral.TextData(CHARSET_TEXT, 0, SData, nil, IID_ITTSBufNotifySink);
    except
    end;
  end;
end;

procedure TSpeechUnit.AddSpeechText(const AText: String);
begin
  MessageQueue.Add(AText);
end;


end.
