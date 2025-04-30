class Base {
  static bool prod = true;
  static bool local = false;
  static String title = prod ? 'Prod' : 'Test';

  static String baseURL = local
      ? 'https://localhost:8480'
      : prod
          ? 'https://demo.primware.net'
          : 'https://testidempiere.com';
}

class EndPoints {
  static String postUserAuth = '${Base.baseURL}/api/v1/auth/tokens';

  static String rRequest = '${Base.baseURL}/api/v1/models/R_Request';

  static String adUser = '${Base.baseURL}/api/v1/models/AD_User';

  static String mWarehouse = '${Base.baseURL}/api/v1/models/M_Warehouse';

  static String cBPartner = '${Base.baseURL}/api/v1/models/C_BPartner';

  static String adUserRoles = '${Base.baseURL}/api/v1/models/AD_User_Roles';

  static String salesRep =
      '${Base.baseURL}/api/v1/models/C_BPartner?\$expand=AD_User(\$select=Name)&\$select=Name,IsSalesRep&\$filter=IsSalesRep eq true';

  static String getOrganizationsAfterLogin =
      '${Base.baseURL}/api/v1/models/AD_Org';

  static String cCurrency = '${Base.baseURL}/api/v1/models/C_Currency';

  static String cCountry = '${Base.baseURL}/api/v1/models/C_Country';

  static String initialclientsetup =
      '${Base.baseURL}/api/v1/processes/initialclientsetup';

  static String mProduct = '${Base.baseURL}/api/v1/models/M_Product';

  static String cOrder = '${Base.baseURL}/api/v1/models/C_Order';
  static String cOrderLine = '${Base.baseURL}/api/v1/models/C_OrderLine';
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
  GetWarehouse(
      {required this.rolID,
      required this.clientID,
      required this.organizationID});

  String get endPoint =>
      '${Base.baseURL}/api/v1/auth/warehouses?client=$clientID&role=$rolID&organization=$organizationID';
}
