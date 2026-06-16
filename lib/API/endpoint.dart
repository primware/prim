class Base {
  static bool prod = false;
  static String title = prod ? 'Prim' : 'Demo Prim';
  static bool allowCreateAccount = true;
  static String? baseURL;
  static String? yappyURL;
}

class EndPoints {
  static String get postUserAuth => '${Base.baseURL}/api/v1/auth/tokens';

  static String get adUser => '${Base.baseURL}/api/v1/models/AD_User';

  static String get adOrg => '${Base.baseURL}/api/v1/models/AD_Org';

  static String get mWarehouse => '${Base.baseURL}/api/v1/models/M_Warehouse';

  static String get cBPartner => '${Base.baseURL}/api/v1/models/C_BPartner';

  static String get cBPartnerLocation =>
      '${Base.baseURL}/api/v1/models/C_BPartner_Location';

  static String get cLocation => '${Base.baseURL}/api/v1/models/C_Location';

  static String get adUserRoles => '${Base.baseURL}/api/v1/models/AD_User_Roles';

  static String get salesRep =>
      '${Base.baseURL}/api/v1/models/C_BPartner?\$expand=AD_User(\$select=Name)&\$select=Name,IsSalesRep&\$filter=IsSalesRep eq true';

  static String get getOrganizationsAfterLogin =>
      '${Base.baseURL}/api/v1/models/AD_Org?\$filter=AD_Org_ID ne 0';

  static String get cCurrency => '${Base.baseURL}/api/v1/models/C_Currency';

  static String get adChart => '${Base.baseURL}/api/v1/models/AD_Chart';

  static String get cCountry => '${Base.baseURL}/api/v1/models/C_Country';

  static String get cCity => '${Base.baseURL}/api/v1/models/C_City';

  static String get rRequest => '${Base.baseURL}/api/v1/models/R_Request';

  static String get cPos => '${Base.baseURL}/api/v1/models/C_POS';

  static String get mProduct => '${Base.baseURL}/api/v1/models/M_Product';

  static String get mProductPrice => '${Base.baseURL}/api/v1/models/M_ProductPrice';

  static String get mProductCategory =>
      '${Base.baseURL}/api/v1/models/M_Product_Category';

  static String get mPriceList => '${Base.baseURL}/api/v1/models/M_PriceList';

  static String get cPaymentTermID => '${Base.baseURL}/api/v1/models/C_PaymentTerm';

  static String get cdsCloseCash => '${Base.baseURL}/api/v1/models/CDS_CloseCash';

  static String get cOrder => '${Base.baseURL}/api/v1/models/C_Order';

  static String get cOrderLine => '${Base.baseURL}/api/v1/models/C_OrderLine';

  static String get cTax => '${Base.baseURL}/api/v1/models/C_Tax';

  static String get cInvoice => '${Base.baseURL}/api/v1/models/C_Invoice';

  static String get adSequence => '${Base.baseURL}/api/v1/models/AD_Sequence';

  static String get cTaxCategory => '${Base.baseURL}/api/v1/models/C_TaxCategory';

  static String get cDocType => '${Base.baseURL}/api/v1/models/C_DocType';

  static String get lcoTaxIdType => '${Base.baseURL}/api/v1/models/LCO_TaxIdType';

  static String get cBPGroup => '${Base.baseURL}/api/v1/models/C_BP_Group';

  static String get adOrgInfo => '${Base.baseURL}/api/v1/models/AD_OrgInfo';

  static String get cdsYappyConf => '${Base.baseURL}/api/v1/models/CDS_YappyConf';

  static String get cdsYappyGroup => '${Base.baseURL}/api/v1/models/CDS_YappyGroup';

  static String get cPOSTenderType =>
      '${Base.baseURL}/api/v1/models/C_POSTenderType';

  static String get yappyDevice => '${Base.yappyURL}/session/device';

  static String get yappyQRGeneratorDYN => '${Base.yappyURL}/qr/generate/DYN';

  static String get yappyTransaction => '${Base.yappyURL}/transaction';
}

class GetCustomerData {
  final String id;

  GetCustomerData({required this.id});

  String get endPoint =>
      '${Base.baseURL}/api/v1/models/C_BPartner?\$expand=AD_User(\$select=EMail,Phone,Phone2,Comments,Birthday,AD_Image_ID)&\$select=Value,Name,Name2,TaxID,Description,SalesRep_ID&\$filter=Value eq \'$id\' or TaxID eq \'$id\'';
}

class GetAttachmentProduct {
  final int recordID;

  GetAttachmentProduct({required this.recordID});

  String get endPoint =>
      '${Base.baseURL}/api/v1/models/AD_Attachment?\$filter=AD_Table_ID eq 208 and record_id eq $recordID';
}

class GetUserData {
  final int adUserID;

  GetUserData({required this.adUserID});

  String get endPoint =>
      '${Base.baseURL}/api/v1/models/AD_User?\$filter=AD_User_ID eq $adUserID';
}

class GetRol {
  final int clientID;

  GetRol({required this.clientID});

  String get endPoint => '${Base.baseURL}/api/v1/auth/roles?client=$clientID';
}

class GetOrganization {
  final int rolID;
  final int clientID;
  GetOrganization({required this.rolID, required this.clientID});

  String get endPoint =>
      '${Base.baseURL}/api/v1/auth/organizations?client=$clientID&role=$rolID';
}

class GetWarehouse {
  final int rolID;
  final int clientID;
  final int organizationID;
  GetWarehouse({
    required this.rolID,
    required this.clientID,
    required this.organizationID,
  });

  String get endPoint =>
      '${Base.baseURL}/api/v1/auth/warehouses?client=$clientID&role=$rolID&organization=$organizationID';
}

class GetProductInPriceList {
  final int mPriceListID;

  GetProductInPriceList({required this.mPriceListID});

  String get endPoint =>
      '${Base.baseURL}/api/v1/models/M_PriceList_Version?\$filter=M_PriceList_ID eq $mPriceListID&\$select=ValidFrom&\$expand=M_ProductPrice(\$select=M_Product_ID)&\$orderby=ValidFrom desc';
}

class GetDocumentActions {
  final int roleID;
  final int docTypeID;

  GetDocumentActions({required this.roleID, required this.docTypeID});

  String get endPoint =>
      '${Base.baseURL}/api/v1/models/AD_Document_Action_Access?\$filter=AD_Role_ID eq $roleID AND C_DocType_ID eq $docTypeID&\$select=AD_Ref_List_ID';
}

class Processes {
  static String get cdsCloseCashProcess =>
      '${Base.baseURL}/api/v1/processes/cds_closecash_process'; // Action
  static String get closeCash =>
      '${Base.baseURL}/api/v1/processes/closecash'; // Report
  static String get syncFE =>
      '${Base.baseURL}/api/v1/processes/factelecsyncinvoice'; // process to sync factura electronica
  static String get createCreditMemo =>
      '${Base.baseURL}/api/v1/processes/cds-invoicecreatecreditmemo';
  static String get orderExecuteDocAction =>
      '${Base.baseURL}/api/v1/processes/orderexecutedocaction';
  static String get changePassword =>
      '${Base.baseURL}/api/v1/processes/setuserpasswordprocesspos';
}

class Charts {
  static int? salesYTDID;
  static int? salesPerDayID;
  static int? salesYTDBySalesRepID;
  static int? salesPerDayByProductCategoryID;

  static String? get salesYTD => salesYTDID != null
      ? '${Base.baseURL}/api/v1/charts/$salesYTDID/data'
      : null;
  static String? get salesPerDay => salesPerDayID != null
      ? '${Base.baseURL}/api/v1/charts/$salesPerDayID/data'
      : null;
  static String? get salesYTDBySalesRep => salesYTDBySalesRepID != null
      ? '${Base.baseURL}/api/v1/charts/$salesYTDBySalesRepID/data'
      : null;
  static String? get salesPerDayByProductCategory =>
      salesPerDayByProductCategoryID != null
      ? '${Base.baseURL}/api/v1/charts/$salesPerDayByProductCategoryID/data'
      : null;
}
