{
   Copyright (C) 2006 The devFlowcharter project.
   The initial author of this file is Michal Domagala.
    
   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
}



unit Element;

interface

uses
   Classes, ExtCtrls, StdCtrls, BaseIterator, ComCtrls, OmniXml, Controls, Forms,
   PageControl_Form, CommonInterfaces;

type
   
   TElement = class(TPanel, ISortable)
      private
         FParentTab: TTabSheet;     // cannot declare as TTabComponent due to 'circular unit reference' error
         FParentForm: TPageControlForm;
         function GetParentTab: TTabSheet;
      protected
         FElem_Id: string;
         constructor Create(AParent: TScrollBox);
         procedure OnClickRemove(Sender: TObject);
         procedure OnChangeType(Sender: TObject);
         procedure OnChangeName(Sender: TObject); virtual;
         procedure UpdateMe;
      public
         edtName: TEdit;
         cbType: TComboBox;
         btnRemove: TButton;
         property ParentTab: TTabSheet read FParentTab;
         property ParentForm: TPageControlForm read FParentForm;
         function ExportToXMLTag(const root: IXMLElement): IXMLElement; virtual;
         procedure ImportFromXMLTag(const root: IXMLElement); virtual;
         function IsValid: boolean; virtual;
         function GetSortValue(const ASortType: integer): integer;
   end;

   TElementIterator = class(TBaseIterator)
   end;

const
   FIELD_IDENT = 'field';
   PARAMETER_IDENT = 'arg';

implementation

uses
   ApplicationCommon, TabComponent, Graphics, SysUtils, SourceEditor_Form;

constructor TElement.Create(AParent: TScrollBox);
begin

   inherited Create(AParent);
   Parent := AParent;
   
   Ctl3D := false;
   BevelOuter := bvNone;
   FParentTab := GetParentTab;
   FParentForm := TTabComponent(FParentTab).ParentForm;
   DoubleBuffered := true;

   edtName := TEdit.Create(Self);
   edtName.Parent := Self;
   edtName.SetBounds(3, 0, 80, 21);
   edtName.ParentFont := false;
   edtName.Font.Style := [];
   edtName.ParentCtl3D := false;
   edtName.Ctl3D := true;
   edtName.ShowHint := true;
   edtName.Hint := i18Manager.GetString('BadIdD');
   edtName.Font.Color := NOK_COLOR;
   edtName.DoubleBuffered := true;
   edtName.OnChange := OnChangeName;

   cbType := TComboBox.Create(Self);
   cbType.Parent := Self;
   cbType.Style := csDropDownList;
   cbType.ParentFont := false;
   cbType.Font.Style := [];
   cbType.Font.Color := clWindowText;
   cbType.OnChange := OnChangeType;

   btnRemove := TButton.Create(Self);
   btnRemove.Parent := Self;
   btnRemove.ParentFont := false;
   btnRemove.Font.Style := [];
   btnRemove.DoubleBuffered := true;
   btnRemove.Caption := i18Manager.GetString('btnRemove');
   btnRemove.OnClick := OnClickRemove;

end;

function TElement.GetParentTab: TTabSheet;
var
   lObject: TWinControl;
begin
   result := nil;
   lObject := Parent;
   while not (lObject is TForm) do
   begin
      if lObject is TTabComponent then
      begin
         result := TTabComponent(lObject);
         break;
      end
      else
         lObject := lObject.Parent;
   end;
end;

procedure TElement.OnClickRemove(Sender: TObject);
begin
   Hide;
   if Parent.Height < Parent.Constraints.MaxHeight then
      Parent.Height := Parent.Height - 22;
   Parent := Parent.Parent;
   FParentForm.UpdateCodeEditor := false;
   TTabComponent(FParentTab).RefreshElements;
   FParentForm.UpdateCodeEditor := true;
   UpdateMe;
   if GSettings.UpdateCodeEditor and not TTabComponent(FParentTab).chkExtDeclare.Checked then
      SourceEditorForm.RefreshEditorForObject(nil);
end;

procedure TElement.OnChangeType(Sender: TObject);
begin
   if GSettings.UpdateCodeEditor and (FParentTab.Font.Color <> NOK_COLOR) and not TTabComponent(FParentTab).chkExtDeclare.Checked then
      SourceEditorForm.RefreshEditorForObject(FParentTab);
   GChange := 1;
end;

function TElement.IsValid: boolean;
begin
   result := true;
   if edtName.Enabled then
   begin
      if (edtName.Font.Color = NOK_COLOR) or (Trim(edtName.Text) = '') then
         result := false;
   end;
end;

procedure TElement.OnChangeName(Sender: TObject);
var
   lInfo: string;
   lColor: TColor;
begin
   if ValidateId(edtName.Text) <> VALID_IDENT then
   begin
      lColor := NOK_COLOR;
      lInfo := 'BadIdD';
   end
   else if TTabComponent(FParentTab).IsDuplicatedElement(Self) then
   begin
      lColor := NOK_COLOR;
      lInfo := 'DupIdD';
   end
   else
   begin
      lColor := OK_COLOR;
      lInfo := 'OkIdD';
   end;
   edtName.Font.Color := lColor;
   edtName.Hint := i18Manager.GetString(lInfo);
   UpdateMe;
   if GSettings.UpdateCodeEditor and FParentForm.UpdateCodeEditor and not TTabComponent(FParentTab).chkExtDeclare.Checked then
      SourceEditorForm.RefreshEditorForObject(FParentTab);
end;

procedure TElement.UpdateMe;
begin
   FParentTab.PageControl.Refresh;
   GChange := 1;
end;

function TElement.GetSortValue(const ASortType: integer): integer;
begin
   result := Top;
end;

procedure TElement.ImportFromXMLTag(const root: IXMLElement);
var
   lIdx: integer;
begin
   edtName.Text := root.GetAttribute('name');
   if cbType.Items.Count > 0 then
   begin
      lIdx := cbType.Items.IndexOf(root.GetAttribute('type'));
      if lIdx = -1 then
         cbType.ItemIndex := 0
      else
         cbType.ItemIndex := lIdx;
   end;
end;

function TElement.ExportToXMLTag(const root: IXMLElement): IXMLElement;
begin
   result := root.OwnerDocument.CreateElement(FElem_Id);
   root.AppendChild(result);
   result.SetAttribute('name', Trim(edtName.Text));
   result.SetAttribute('type', cbType.Text);
end;

end.