# SnapshotFailLocator

For when Snapshot fails, and you're too lazy to search for the test failure images.

### Requirements

Xcode 9.2 w/ Swift 4 or later.

### Running

Run on the command line:

```
$ swift run
```

### Usage

The program searches at the temporary files from all simulator devices for 'failed_*.png' files, and lists them sorted by most recently changed.

```
Snapshot files found - most recent first:
----
1:  Hoje 11:25 - SupportAlertDetailsViewControllerSpec/failed_SupportAlertDetailsViewController___closed@2x.png
2:  Hoje 11:24 - GridSubMenuTableViewControllerSpec/failed_GridSubMenuTableViewController___Items@2x.png
3:  02/02/2018 12:43 - TravaWarningViewControllerSpec/failed_when_instantiate_TravaViewController_with_alterned_Bandeiras__view_is_ready_to_hve_one_trava_Master@2x.png
4:  02/02/2018 12:43 - TravaWarningViewControllerSpec/failed_when_instantiate_TravaViewController_with_alterned_Bandeiras__view_is_ready_to_hve_one_trava_visa@2x.png
5:  02/02/2018 12:43 - TravaWarningViewControllerSpec/failed_when_instantiate_TravaViewController__view_is_ready_if_no_have_any_trava@2x.png
6:  02/02/2018 12:43 - TableViewSectionableDataSourceDelegateSpec/failed_test_hide_warning@2x.png
7:  02/02/2018 12:43 - TableViewSectionableDataSourceDelegateSpec/failed_test_show_warning@2x.png
8:  02/02/2018 12:43 - SupportTutorialPageViewControllerSpec/failed_SupportTutorialPageViewController___exibi__op1@2x.png
9:  02/02/2018 12:43 - SupportTutorialPageViewControllerSpec/failed_SupportTutorialPageViewController___exibi__op2@2x.png
10: 02/02/2018 12:42 - SupportAlertDetailsViewControllerSpec/failed_SupportAlertDetailsViewController___closed@2x.png
11: 02/02/2018 12:42 - SupportAlertDetailsViewControllerSpec/failed_SupportAlertDetailsViewController@2x.png
12: 02/02/2018 12:42 - SelecaoValorViewControllerSpec/failed_when_instantiate_SelecaoValorViewController__should_config_the_api_and_produtosParcelados@2x.png
13: 02/02/2018 12:42 - SelecaoOutroValorViewControllerSpec/failed_when_instantiate_SelecaoValorViewController__should_config_the_api_and_produtosParcelados@2x.png
14: 02/02/2018 12:42 - ReceiptPaymentViewControllerSpec/failed_receipt_boletos_authorization@2x.png
15: 02/02/2018 12:42 - ReceiptPaymentViewControllerSpec/failed_receipt_demaisTributos_authorization@2x.png
16: 02/02/2018 12:42 - ReceiptPaymentViewControllerSpec/failed_when_type_is_GARE__should_have_the_expected_layout_when_screen_loads@2x.png
17: 02/02/2018 12:42 - ReceiptPaymentViewControllerSpec/failed_given_ReceiptConcessionariaViewController__when_type_is_Demais_Tributos__should_have_the_expected_layout_when_screen_loads@2x.png
18: 02/02/2018 12:42 - ReceiptPaymentViewControllerSpec/failed_given_ReceiptConcessionariaViewController__when_type_is_FGTS__should_have_the_expected_layout_when_screen_loads@2x.png
19: 02/02/2018 12:42 - ReceiptPaymentViewControllerSpec/failed_given_ReceiptConcessionariaViewController__when_type_is_GPS__should_have_the_expected_layout_when_screen_loads@2x.png
20: 02/02/2018 12:42 - ReceiptPaymentViewControllerSpec/failed_given_ReceiptConcessionariaViewController__when_type_is_concessionaria__should_have_the_expected_layout_when_screen_loads@2x.png
21: 02/02/2018 12:42 - PreLoginViewControllerSpec/failed_PreLoginViewController_openAccount@2x.png
22: 02/02/2018 12:42 - PreLoginViewControllerSpec/failed_PreLoginViewController_openApp@2x.png
23: 02/02/2018 12:42 - PreLoginViewControllerSpec/failed_PreLoginViewController_openHelp@2x.png
24: 02/02/2018 12:42 - PreLoginViewControllerSpec/failed_PreLoginViewController_accessToken@2x.png
25: 02/02/2018 12:42 - PreLoginViewControllerSpec/failed_PreLoginViewController_agencyAndAccount@2x.png
26: 02/02/2018 12:42 - PreLoginViewControllerSpec/failed_PreLoginViewController_operatorCode@2x.png
27: 02/02/2018 12:42 - PreLoginViewControllerSpec/failed_PreLoginViewController@2x.png
28: 02/02/2018 12:42 - PaymentDetailViewControllerSpec/failed_payment_boleto_itau@2x.png
29: 02/02/2018 12:42 - PaymentDetailViewControllerSpec/failed_payment_boleto_inclusion@2x.png
30: 02/02/2018 12:42 - PaymentDetailViewControllerSpec/failed_payment_boletos_authorization@2x.png
---- 1 to 30
= Page 1 of 3
Input page (0 or empty to close):
Specify an entry number to open its containing folder
> _
```

Selecting a number `<n>` opens the file at the given index on Finder.

Specifying an index after an equals sign, e.g. `=2`, switches the page displayed, in case more than 30 results are found.

##### Quitting

Enter an empty string or `0` to quit.