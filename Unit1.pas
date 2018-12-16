unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,LibEWFUnit, ComCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Button2: TButton;
    pb_img: TProgressBar;
    Button3: TButton;
    OpenDialog1: TOpenDialog;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
        {/*
          * TPartitionInfo - record type containing disk partition information.
          */}
        TPartitionInfo = record
                partType : byte;
                offset, length : int64;
                partNo : integer;
        end;
        TDynArrayPartitionInfo = array of TPartitionInfo;  

var
  Form1: TForm1;
  fLibEWF:TLibEWF;
  

implementation

{$R *.dfm}

function _Get_FileSize2(const FileName: string): TULargeInteger;
// by nico
var
  Find: THandle;
  Data: TWin32FindData;
begin
  Result.QuadPart := 0;
  Find := FindFirstFile(PChar(FileName), Data);
  if (Find <> INVALID_HANDLE_VALUE) then
  begin
    Result.LowPart  := Data.nFileSizeLow;
    Result.HighPart := Data.nFileSizeHigh;
    Windows.FindClose(Find);
  end;
end;

{/*
  * (Private) Add (to a partition list) partition information from a chain of Extended Boot Record partition tables.
  * @param partNo - the 'logical' partition number  to assign to this partition.
  * @param EBROffset - offset of the EBR to read.
  * @param partitions - a list of partitions to add to.
  * @return The number of partitions read.
  */}
procedure addEBRPartitionInfo(partNo: integer; EBROffset : int64; var partitions : TDynArrayPartitionInfo);
var
        rwBuf : array[0..31] of byte;
        lengthRead, pCount : integer;
        partitionStatus, partitionType : byte;
        startLBA, totalBlocks : int64;
begin
        startLBA:=0;
        totalBlocks:=0;
        lengthRead:=fLibEWF.libewf_read_buffer_at_offset(@rwBuf[0], 32, $01BE+EBROffset);
        if lengthRead=32 then
        begin
                Move(rwBuf[0], partitionStatus, 1);
                if (partitionStatus=$00) or (partitionStatus=$80) then  //add to the list
                begin
                        startLBA:=0;
                        totalBlocks:=0;
                        Move(rwBuf[4], partitionType, 1);
                        Move(rwBuf[8], startLBA, 4);
                        Move(rwBuf[12], totalBlocks, 4);
                        SetLength(partitions, Length(partitions)+1);
                        partitions[high(partitions)].partType:=partitionType;
                        partitions[high(partitions)].offset:=EBROffset+(startLBA*512);
                        partitions[high(partitions)].length:=totalBlocks*512;
                        partitions[high(partitions)].partNo:=partNo;
                end;

                Move(rwBuf[24], startLBA, 4);
                if startLBA<>0 then
                        addEBRPartitionInfo(partNo+1, EBROffset+(startLBA*512), partitions); //get the next logical drive (EBR).

        end;
end;

{/*
  * Add (to a partition list) partition information from the currently open EWF file.
  * @param partitions - a list of partitions to add to.
  * @return The number of partitions read.
  */}
function getMBRPartitionInfo(var partitions : TDynArrayPartitionInfo) : integer;
var
        rwBuf : array[0..17] of byte;
        lengthRead, pCount : integer;
        partitionStatus, partitionType : byte;
        startLBA, totalBlocks : int64;
begin
        SetLength(partitions, 0);

        Result:=0;
        for pCount:=0 to 3 do
        begin
                lengthRead:=fLibEWF.libewf_read_buffer_at_offset(@rwBuf[0], 16, $01BE+(pCount*16));
                if lengthRead=16 then
                begin
                        Move(rwBuf[0], partitionStatus, 1);
                        if (partitionStatus=$00) or (partitionStatus=$80) then
                        begin
                                startLBA:=0;
                                totalBlocks:=0;

                                Move(rwBuf[4], partitionType, 1);
                                Move(rwBuf[8], startLBA, 4);
                                Move(rwBuf[12], totalBlocks, 4);

                                if partitionType<>$00 then //is a partition entry
                                begin
                                        if (partitionType=$05) or (partitionType=$0f) then //extended partition
                                        begin
                                                addEBRPartitionInfo(5, (startLBA)*512, partitions);
                                        end
                                        else //add to the list
                                        begin
                                                SetLength(partitions, Length(partitions)+1);
                                                partitions[high(partitions)].partType:=partitionType;
                                                partitions[high(partitions)].offset:=startLBA*512;
                                                partitions[high(partitions)].length:=totalBlocks*512;
                                                partitions[high(partitions)].partNo:=pCount+1;
                                        end;
                                end;
                        end;
                end;
        end;
        Result:=Length(partitions);
end;

procedure TForm1.Button1Click(Sender: TObject);
var
partitions:TDynArrayPartitionInfo ;
mediaSize:int64;
value:ansistring;
begin
memo1.Clear ;
OpenDialog1.Filter :='E01|*.E01';
if OpenDialog1.Execute =false then exit;

//E01, S01, L01 (r/o)
fLibEWF:=TLibEWF.create;
if fLibEWF.libewf_open(OpenDialog1.FileName )=0 then
  begin
  mediaSize:=fLibEWF.libewf_get_media_size;
  if getMBRPartitionInfo(partitions)>0 then
    begin
    memo1.Lines.Add('mediaSize:'+inttostr(mediaSize));
    memo1.Lines.Add('partno:'+inttostr(partitions [0].partno));
    memo1.Lines.Add('partType:'+inttostr(partitions [0].partType));
    memo1.Lines.Add('offset:'+inttostr(partitions [0].offset));
    memo1.Lines.Add('length:'+inttostr(partitions [0].length));
    end;
  if fLibEWF.libewf_GetHeaderValue('acquiry_software_version',value)=1
    then memo1.Lines.Add('acquiry_software_version:'+value);
  if fLibEWF.libewf_GetHeaderValue('acquiry_date',value)=1
    then memo1.Lines.Add('acquiry_date:'+value);
  if fLibEWF.libewf_GetHashValue('MD5',value)=1
    then memo1.Lines.Add('MD5:'+value);
  end;
fLibEWF.libewf_close;
FreeAndNil(fLibEWF);
end;

procedure TForm1.Button2Click(Sender: TObject);
var
ipos,mediasize:int64;
lengthRead:integer;
buffer:array of byte;
//buffer:pointer;
memsize,BufferSize:integer;
byteswritten:cardinal;
ret:boolean;
hDevice_dst:thandle;
dst,src:string;
start:cardinal;
begin
OutputDebugString(pchar('start'));
memo1.Clear ;
memsize:=1024*64;BufferSize:=memsize;
ipos:=0;

OpenDialog1.Filter :='E01|*.E01';
if OpenDialog1.Execute =false then exit;
src:=OpenDialog1.FileName ;

dst:=ChangeFileExt(src,'.dd'); 
{$i-}deletefile(dst);{$i-}

fLibEWF:=TLibEWF.create;
try
if fLibEWF.libewf_open(src,LIBEWF_OPEN_READ)=0 then
  begin
    mediaSize:=fLibEWF.libewf_get_media_size;
    pb_img.Max :=mediasize;
    memo1.lines.add('starting');
    //VirtualAlloc (buffer,memsize,MEM_COMMIT or MEM_RESERVE, PAGE_READWRITE); 
    setlength(buffer,memsize );
    hDevice_dst := CreateFile(pchar(dst), GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, CREATE_NEW, 0 , 0);
    start:=GetTickCount ;
    while (lengthRead>0)  do
    begin
    if ipos+BufferSize >mediasize then BufferSize :=mediasize -ipos;
    lengthRead:=fLibEWF.libewf_read_buffer_at_offset(@buffer[0], BufferSize, ipos);
    if lengthRead>0 then
      begin
      ret:=WriteFile (hDevice_dst, buffer[0], lengthRead, byteswritten, nil);
      if (ret=false) or (byteswritten<>lengthRead) then memo1.Lines.Add('writefile failed');
    end;
    ipos:=ipos+BufferSize ;
    pb_img.Position :=ipos;
    end; //while
    closehandle(hDevice_dst);
    memo1.lines.add('done in '+inttostr(GetTickCount -start)+'ms');
    //virtualfree(buffer,memsize ,MEM_RELEASE );
    //fLibEWF.libewf_close; //will be done in the free/destroy
  end;//if fLibEWF.libewf_open
finally
FreeAndNil(fLibEWF);
end;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
buffer:array of byte;
memsize,BufferSize:integer;
ipos,mediasize:int64;
hDevice_Src:thandle;
src,dst:string;
ret:boolean;
bytesread,byteswritten,start:cardinal;
begin
memo1.Clear ;
memsize:=1024*64;BufferSize:=memsize;

OpenDialog1.Filter :='img|*.img;*.dd';
if OpenDialog1.Execute =false then exit;
src:=OpenDialog1.FileName ;

dst:=ChangeFileExt(src,'.e01');
{$i-}deletefile(dst);{$i-}

mediasize:=_Get_FileSize2(src).QuadPart ;
pb_img.Max :=mediasize;
ipos:=0;
setlength(buffer,memsize );
fLibEWF:=TLibEWF.create;
try

if fLibEWF.libewf_open(dst,LIBEWF_OPEN_WRITE)=0 then
  begin
  fLibEWF.libewf_SetCompressionValues(LIBEWF_COMPRESSION_METHOD_DEFLATE,LIBEWF_COMPRESS_FLAG_USE_EMPTY_BLOCK_COMPRESSION);
  fLibEWF.libewf_SetHeaderValue('acquiry_software_version','CloneDisk');
  memo1.lines.add('starting');
  hDevice_Src := CreateFile(pchar(src), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  ret:=true;
  start:=GetTickCount ;
  while ret<>false do
    begin
    if ipos+BufferSize >mediasize then BufferSize :=mediasize -ipos;
    ret:=ReadFile (hDevice_Src, buffer[0], buffersize, bytesread, nil);
    if bytesread=0 then break;
    if ret=true
      then byteswritten:=fLibEWF.libewf_write_buffer_at_offset (@buffer[0], BufferSize, ipos)
      //then byteswritten:=fLibEWF.libewf_write_buffer (@buffer[0], BufferSize)
      else memo1.Lines.Add('readfile failed');
    ipos:=ipos+BufferSize ;
    pb_img.Position :=ipos;
    end; //while
  memo1.lines.add('done in '+inttostr(GetTickCount -start)+'ms');
  closehandle(hDevice_Src);
  //fLibEWF.libewf_close;
  end;
finally
FreeAndNil(fLibEWF);
end;
end;

end.
