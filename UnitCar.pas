unit UnitCar;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IOUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Sensors,
  FMX.StdCtrls, FMX.WebBrowser, System.Sensors.Components, FMX.Edit,
  FMX.Controls.Presentation, System.Android.Sensors, FMX.ScrollBox, FMX.Memo,
  System.ImageList, FMX.ImgList, FMX.ListBox, FMX.Layouts, FMX.MultiView;

type
  t_locstring=record         //coordinates expressed as strings
    Latitude,
    Longitude:String;
  end;

type
  TForm5 = class(TForm)
    PanelTitle: TPanel;
    PanelCom: TPanel;
    EditDestLong: TEdit;
    EditDestlat: TEdit;
    EditOriginLong: TEdit;
    EditOriginLat: TEdit;
    GoBtn: TButton;
    LocationSensor1: TLocationSensor;
    PanelBottom: TPanel;
    Switch1: TSwitch;
    Label1: TLabel;
    Memo1: TMemo;
    WebBrowser1: TWebBrowser;
    AnchorBtn: TSpeedButton;
    ImageList1: TImageList;
    ClearBtn: TSpeedButton;
    LabelTitle: TLabel;
    PanelLoc: TPanel;
    LocRecLabel: TLabel;
    LocDetailBtn: TSpeedButton;
    Layout1: TLayout;
    MultiView1: TMultiView;
    ToolBarTopMW: TToolBar;
    MWTitleLabel: TLabel;
    ListBox1: TListBox;
    ListBoxGroupHeader1: TListBoxGroupHeader;
    ListBoxItemLatitude: TListBoxItem;
    ListBoxItemLongitude: TListBoxItem;
    ListBoxGroupHeader2: TListBoxGroupHeader;
    ListBoxItemStreetNo: TListBoxItem;
    ListBoxItemNBhood: TListBoxItem;
    ListBoxItemCity: TListBoxItem;
    ListBoxItemZipcode: TListBoxItem;
    ListBoxItemCountry: TListBoxItem;
    HideMWBtn: TButton;
    procedure FormCreate(Sender: TObject);
    procedure LocationSensor1LocationChanged(Sender: TObject; const OldLocation,
      NewLocation: TLocationCoord2D);
    procedure Switch1Switch(Sender: TObject);
    procedure GoBtnClick(Sender: TObject);
    procedure AnchorBtnClick(Sender: TObject);
    procedure ClearBtnClick(Sender: TObject);
    procedure LocDetailBtnClick(Sender: TObject);
    procedure HideMWBtnClick(Sender: TObject);
  private
    { Private declarations }
    LocFile:TStringList;
    FGeocoder: TGeocoder;
    procedure OnGeocodeReverseEvent(const Address: TCivicAddress);
    procedure DisplayActualLocation(Location: t_locstring);
    procedure DisplayCarPath(FromLoc: t_locstring);
    procedure EnabButtons(habit:boolean);
    procedure UseGeocoder(where:TLocationCoord2D);
  public
    { Public declarations }
  end;




var
  Form5: TForm5;

implementation

{$R *.fmx}
{$R *.NmXhdpiPh.fmx ANDROID}
{$I-}


var
  FileName,                     //text file with the location recorded
  Markexist: String;            //word that indicates if a location is recorded
  CarLoc, ActualLoc: t_locstring;     // actual location and car location
  //variables used by the geocoder
  Thoroughfare,SubThoroughfare,Locality,SubLocality,PostalCode,CountryName: String ;

const
  //labels that indicates if there are a location recorded
  LabelLocArr:array[0..1]of String =('No location recorded','Your car is at');


//In the first application run, a textfile entitled 'loc.txt' is created. It is saved with a word 'no'
//In the further runs, if a location is recorded in the file, it is read
procedure TForm5.FormCreate(Sender: TObject);
var
  F1: TextFile;
begin
  FormatSettings.DecimalSeparator := '.';
  LocFile:=TStringList.Create;                   //strings with the location information
  try
    FileName:=TPath.Combine(TPath.GetDocumentsPath, 'loc.txt');   //path of the text file
    Memo1.Lines.Add(FileName);
    ActualLoc.Latitude:='0.0';
    ActualLoc.Longitude:='0.0';            //inicializate actual location
    if not(FileExists(FileName)) then      //if file does not exist it is created
      begin
          AssignFile(F1,FileName);
          rewrite(F1);
          Markexist:='no';
          writeln(F1,'no');                //saves only the word 'no'
          closeFile(F1);
          Memo1.Lines.Add('Text file created')
      end
      else
      begin
        LocFile.LoadFromFile(FileName);      //otherwise, the file is read
        Markexist:=LocFile.Strings[0];
        if Markexist='yes' then               //if there is a location recorded, it is read
          begin
            CarLoc.Latitude:=LocFile.Strings[1];
            CarLoc.Longitude:=LocFile.Strings[2];
            //EditDestLat.Text:=CarLoc.Latitude;
            //EditDestLong.Text:=CarLoc.Longitude;
          end;
      end;
      LocDetailBtn.Visible:=(Markexist='yes');          //label and button are enabled
      LocRecLabel.Text:=LabelLocArr[Ord(Markexist='yes')];  //or disabled
  except
    on EInOutError do
      ShowMessage('IO Result: '+IntToStr(IOResult))
  end
end;

//to be deleted
procedure TForm5.GoBtnClick(Sender: TObject);
//  var
//  URLString:String;
begin
  //URLString:='https://www.google.com/maps/dir/'+EditOriginLat.Text+','+EditOriginLong.Text+'/'+EditDestLat.Text+','+EditDestLong.Text+'/data=!3m1!4b1!4m2!4m1!3e2';
  //WebBrowser1.Navigate(URLString);
end;


//switch state is equal to sensor location state
procedure TForm5.Switch1Switch(Sender: TObject);
begin
  LocationSensor1.Active := Switch1.IsChecked;
  AnchorBtn.Enabled:=(Switch1.IsChecked) and (Markexist='no');   //enables or disables the buttons
  ClearBtn.Enabled:=(Switch1.IsChecked) and (Markexist='yes');
end;

//display actual location
procedure TForm5.DisplayActualLocation(Location: t_locstring);
var
  URLString: String;
begin
  URLString:='https://maps.google.com/maps?q='+Location.Latitude+','+Location.Longitude;
  WebBrowser1.Navigate(URLString);
end;

//display path to the car from the actual location
procedure TForm5.DisplayCarPath(FromLoc: t_locstring);
var
  URLString: String;
begin
  //EditDestlat.Text:=CarLoc.Latitude;
  //EditDestLong.Text:=CarLoc.Longitude;
  URLString:='https://www.google.com/maps/dir/'+FromLoc.Latitude+','+FromLoc.Longitude+'/'+CarLoc.Latitude+','+CarLoc.Longitude+'/data=!3m1!4b1!4m2!4m1!3e2';
  WebBrowser1.Navigate(URLString);
end;


//event executed when the location sensor detects a movement
procedure TForm5.LocationSensor1LocationChanged(Sender: TObject;
  const OldLocation, NewLocation: TLocationCoord2D);
begin
  //the following 4 lines are going to be deleted
  //EditDestLat.Text:=FloatToStrf(OldLocation.Latitude,ffFixed,12,9);
  //EditDestLong.Text:=FloatToStrf(OldLocation.Longitude,ffFixed,12,9);
  //EditOriginLat.Text:=FloatToStrf(NewLocation.Latitude,ffFixed,12,9);
  //EditOriginLong.Text:=FloatToStrf(NewLocation.Longitude,ffFixed,12,9);
  ActualLoc.Latitude:=FloatToStrf(NewLocation.Latitude,ffFixed,12,9);    //updates the variables ActualLoc
  ActualLoc.Longitude:=FloatToStrf(NewLocation.Longitude,ffFixed,12,9);
  //if no location is recorded on the file
  if Markexist='no' then
       DisplayActualLocation(ActualLoc);
  //if a location is recorded on the file
  if Markexist='yes' then
       DisplayCarPath(ActualLoc);
  //Memo1.Lines.Add('Location recorded: '+Markexist);
end;



  (*************************************************************************)
//procedures that use the geocoder
procedure TForm5.UseGeocoder(where: TLocationCoord2D);
begin
  // Setup an instance of TGeocoder
  try
    if not Assigned(FGeocoder) then
    begin
      if Assigned(TGeocoder.Current) then
        FGeocoder := TGeocoder.Current.Create;
      if Assigned(FGeocoder) then
        FGeocoder.OnGeocodeReverse := OnGeocodeReverseEvent;
    end;
  except
    ShowMessage('Geocoder service error');
  end;
  // Translate location to address
  if Assigned(FGeocoder) and not FGeocoder.Geocoding then
    FGeocoder.GeocodeReverse(where);
end;

procedure TForm5.OnGeocodeReverseEvent(const Address: TCivicAddress);
begin
  Thoroughfare:=Address.Thoroughfare;
  SubThoroughfare:=Address.SubThoroughfare;
  SubLocality:=Address.SubLocality;
  Locality:=Address.Locality;
  PostalCode:=Address.PostalCode;
  CountryName:=Address.CountryName;
end;


//show car location details
procedure TForm5.LocDetailBtnClick(Sender: TObject);
var
  locat: TLocationCoord2D;
begin
   locat.Latitude:=StrToFloat(CarLoc.Latitude);
   locat.Longitude:=StrToFloat(CarLoc.Longitude);
   UseGeocoder(locat);
   Memo1.Lines.Clear;
   Memo1.Lines.Add('Your car is at: '+Thoroughfare+' '+SubThoroughfare+' '+SubLocality+', '+PostalCode+' '+Locality+' '+CountryName);
   //Popup1.IsOpen:=true;             //open popup menu
   ListBoxItemLatitude.Text:='Latitude: '+FloatToStrf(locat.Latitude,ffFixed,9,6);
   ListBoxItemLongitude.Text:='Longitude: '+FloatToStrf(locat.Longitude,ffFixed,9,6);
   ListBoxItemStreetNo.Text:=Thoroughfare+' '+SubThoroughfare;
   ListBoxItemNBhood.Text:=Sublocality;
   ListBoxItemCity.Text:=Locality;
   ListBoxItemZipcode.Text:=PostalCode;
   ListBoxItemCountry.Text:=CountryName;
   MultiView1.ShowMaster;
end;

//close popup menu
procedure TForm5.HideMWBtnClick(Sender: TObject);
begin
  MultiView1.HideMaster;
end;

(*************************************************************************)
//Bottom panel buttons

//procedure to enable/disabele buttons according to if there are location recorded or not
procedure TForm5.EnabButtons(habit:boolean);
begin
  AnchorBtn.Enabled:=not(habit);
  ClearBtn.Enabled:=habit;
  LocDetailBtn.Visible:=habit;
  LocRecLabel.Text:=LabelLocArr[Ord(habit)]
end;

//Record location button
procedure TForm5.AnchorBtnClick(Sender: TObject);
begin
  LocFile.Strings[0]:='yes';
  LocFile.Add(ActualLoc.Latitude);
  LocFile.Add(ActualLoc.Longitude);
  LocFile.SaveToFile(FileName, TEncoding.UTF8);
  Markexist:='yes';
  CarLoc:=ActualLoc;
  EnabButtons(true)
end;

//Clear Location Button
procedure TForm5.ClearBtnClick(Sender: TObject);
begin
  Memo1.Lines.Clear;
  LocFile.Clear;
  LocFile.Add('no');
  LocFile.SaveToFile(FileName, TEncoding.UTF8);
  Markexist:='no';
  CarLoc.Latitude:='';
  CarLoc.Longitude:='';
  EnabButtons(false)
end;

end.
