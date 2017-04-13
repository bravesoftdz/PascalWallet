unit frmmain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, httpsend, synacode;

  Const
    CT_INI_SECTION_GLOBAL = 'GLOBAL';
    CT_INI_IDENT_SAVELOGS = 'SAVELOGS';
    CT_INI_IDENT_NODE_PORT = 'NODE_PORT';
    CT_INI_IDENT_NODE_MAX_CONNECTIONS = 'NODE_MAX_CONNECTIONS';
    CT_INI_IDENT_RPC_PORT = 'RPC_PORT';
    CT_INI_IDENT_RPC_WHITELIST = 'RPC_WHITELIST';
    CT_INI_IDENT_RPC_SAVELOGS = 'RPC_SAVELOGS';
    CT_INI_IDENT_RPC_SERVERMINER_PORT = 'RPC_SERVERMINER_PORT';
    CT_INI_IDENT_MINER_B58_PUBLICKEY = 'RPC_SERVERMINER_B58_PUBKEY';
    CT_INI_IDENT_MINER_NAME = 'RPC_SERVERMINER_NAME';
    CT_INI_IDENT_MINER_MAX_CONNECTIONS = 'RPC_SERVERMINER_MAX_CONNECTIONS';

type

  { TFormMain }

  TFormMain = class(TForm)
    btTransactions: TButton;
    btAccountChange: TButton;
    btShowPubKey: TButton;
    cbChngAccounts: TComboBox;
    edAccountPayload: TEdit;
    edAccoundtFee: TEdit;
    edUrl: TEdit;
    edPort: TEdit;
    edPubKey: TEdit;
    Image1: TImage;
    Label1: TLabel;
    lbAccountPayload: TLabel;
    lbAccountFee: TLabel;
    lbUrl: TLabel;
    lbPort: TLabel;
    lbPubKey: TLabel;
    lbAllAccounts: TLabel;
    lbTotalBalance: TLabel;
    mmAbout: TMemo;
    mmHelp: TMemo;
    mmTransactions: TMemo;
    TabSheet5: TTabSheet;
    btRefresh: TButton;
    btnSend: TButton;
    btnCancel: TButton;
    test2: TButton;
    cbAccounts: TComboBox;
    edReceiver: TEdit;
    edAmount: TEdit;
    edFee: TEdit;
    lbPayload: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lbReceiver: TLabel;
    LlbAmont: TLabel;
    lbFee: TLabel;
    Label4: TLabel;
    lbBalance1: TLabel;
    lbBalance: TLabel;
    mmLog: TMemo;
    mmPayload: TMemo;
    PageControl1: TPageControl;
    rgEncrypt: TRadioGroup;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    procedure btAccountChangeClick(Sender: TObject);
    procedure btShowPubKeyClick(Sender: TObject);
    procedure btTransactionsClick(Sender: TObject);
    procedure btRefreshClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure test2Click(Sender: TObject);
    procedure cbAccountsChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { private declarations }
    FSelectedAccount: string;
    FPublicKey: string;
    function SendRequest(method, params: string): String;
    function String2Hex(const Buffer: Ansistring): string;
    function ParseJsonString(Str: string):string;

  public
    { public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

{ TFormMain }
function TFormMain.String2Hex(const Buffer: Ansistring): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(Buffer) do
  Result := UpperCase(Result + IntToHex(Ord(Buffer[i]), 2));
end;

{$IFDEF UNIX}
const eol = #10;
{$ELSE}
const eol = #13#10;
{$ENDIF}

function TFormMain.ParseJsonString(Str: string): string;
//
var
  i, j: Integer;
  s, t: string;
begin
  Result := '';
  for i := 1 to Length(str) do
  begin
    t := Str[i];
    if t = ',' then t := eol
    else if t = '{' then t := eol
    else if t = '}' then t := eol;
    s := s + t;
  end;
  Result := s;
end;

procedure TFormMain.FormActivate(Sender: TObject);
begin
  btRefreshClick(self);
end;

function TFormMain.SendRequest(method, params: string): String;
var
    response: TMemoryStream;
    request, str, url: string;
begin
  request := '{"jsonrpc":"2.0","method":"' + method + '","params":{' + params + '},"id":123}';
  mmLog.Lines.Add('send: ' + request);
  str := '';
  result := '';
  url := 'http://' + Trim(edUrl.Text) + ':' + Trim(edPort.Text);
  response := TMemoryStream.Create;
  try
    if HttpPostURL(url, request, response) then
    begin
         SetLength(str, response.Size);
         Move(response.memory^, str[1], response.size);
    end;
  finally
    response.Free;
  end;
  result := str;
end;

procedure TFormMain.btRefreshClick(Sender: TObject);

var
  str, st, s: string;
  i: integer;
begin
  str := SendRequest('nodestatus', '');
  mmLog.Lines.Add(str);
  if Pos('"ready":true', str) < 1 then
  begin
    showmessage('No Connection - Check Url and Port Settings');
    Exit;
  end;

  str := SendRequest('getwalletaccounts', '');
  mmLog.Lines.Add(str);
  st := str;
  while Pos('"account":', st) > 0 do
  begin
    i := Pos('"account":', st);
    if i > 0 then
    begin
      s := copy(st, i + 10, 10);
      cbAccounts.Items.Add(copy(s, 1, pos(',', s)-1));
    end;
    delete(st, 1, i + 20);
  end;
  cbAccounts.ItemIndex := 0;
  cbChngAccounts.Items :=  cbAccounts.Items;
  cbAccountsChange(self);

  str := SendRequest('getwalletcoins', '');
  i := Pos('"result":', str);
  if i > 0 then
  begin
    s := copy(str, i + 9, Pos(',', str)-(i+10));
    if Pos('.', s)>0 then lbTotalBalance.Caption := s
    else lbTotalBalance.Caption := s + '.0000';
    mmLog.Lines.Add(str);
  end;
end;

procedure TFormMain.btTransactionsClick(Sender: TObject);
var
  str, s: string;
  i: integer;
begin
  mmTransactions.Lines.Clear;
  str := SendRequest('getaccountoperations', '"account":' + FSelectedAccount);
  mmTransactions.Lines.Add(ParseJsonString(str));
end;

procedure TFormMain.btAccountChangeClick(Sender: TObject);
var
  str, params: string;
begin
  //* add some checking
   params := '"account":' + Trim(cbChngAccounts.Items[cbChngAccounts.ItemIndex]) +
   ',"new_enc_pubkey":"' +  edPubKey.Text +
   '","fee":0.0000' +
   ',"payload":"' +
   '","payload_method":"none"';
   str := SendRequest('changekey', params);
   mmLog.Lines.Add(str);

end;

procedure TFormMain.btShowPubKeyClick(Sender: TObject);
begin
  ShowMessage(FPublicKey);
end;

procedure TFormMain.btnSendClick(Sender: TObject);
var
  str, s, params: string;
begin
  //* add some checking
  if Pos('-', edReceiver.Text) > 0 then s :=  Trim(Copy(edReceiver.Text, 1, Pos('-', edReceiver.Text)-1))
  else s := Trim(edReceiver.Text);

  params := '"sender":' + FSelectedAccount +
  ',"target":' + s +
  ',"amount":' + Trim(edAmount.Text) +
  ',"fee":' + Trim(edFee.Text) +
  ',"payload":"' + String2Hex(Trim(mmPayload.Text))+ '","payload_method":"none","pwd":""';
  str := SendRequest('sendto', params);
  mmLog.Lines.Add(str);
  btnCancelClick(self);
end;

procedure TFormMain.btnCancelClick(Sender: TObject);
begin
  edReceiver.Text := '';
  edAmount.Text := '0.0000';
  edFee.Text := '0.0000';
  rgEncrypt.ItemIndex := 0;
  mmPayload.Lines.Clear;
end;

procedure TFormMain.test2Click(Sender: TObject);
begin
  //*
end;

procedure TFormMain.cbAccountsChange(Sender: TObject);
var
    s, str, method, params: string;
    i, f: integer;
begin
  FSelectedAccount := Trim(cbAccounts.Items[cbAccounts.ItemIndex]);
  params := '"account":' + FSelectedAccount;
  str := SendRequest('getaccount', params);
  i := Pos('"balance":', str);
  if i > 0 then
  begin
    s := copy(str, i + 10, 10);
    s := copy(s, 1, pos(',', s)-1);
    if Pos('.',s) > 0 then lbBalance.Caption := s
    else lbBalance.Caption := s + '.0000';
  end
  else lbBalance.Caption := '0.0000';

  FPublicKey := '';
  i := Pos('"enc_pubkey":"', str);
  if i > 0 then
  begin
    s := copy(str, i + 14, 160);
    FPublicKey := copy(s, 1, pos('",', s)-1);
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FSelectedAccount := '';
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
//*
end;


end.

