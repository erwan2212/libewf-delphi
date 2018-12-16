object Form1: TForm1
  Left = 408
  Top = 111
  Width = 389
  Height = 296
  Caption = 'LibEWF'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 16
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Check'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 16
    Top = 48
    Width = 337
    Height = 169
    Lines.Strings = (
      'Memo1')
    TabOrder = 1
  end
  object Button2: TButton
    Left = 104
    Top = 8
    Width = 75
    Height = 25
    Caption = 'EWF->RAW'
    TabOrder = 2
    OnClick = Button2Click
  end
  object pb_img: TProgressBar
    Left = 16
    Top = 224
    Width = 337
    Height = 17
    TabOrder = 3
  end
  object Button3: TButton
    Left = 192
    Top = 8
    Width = 75
    Height = 25
    Caption = 'RAW->EWF'
    TabOrder = 4
    OnClick = Button3Click
  end
  object OpenDialog1: TOpenDialog
    Left = 72
    Top = 208
  end
end
