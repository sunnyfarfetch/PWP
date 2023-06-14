# Problem:

Currently, Vista doesn't have the functionality to link SL AP Invoices that are Pay When Paid to JB Invoices. This causes clients to be confused at when to pay the subcontractor. Clients usually just tie all SL AP invoices to one contract item, which is incorrect. 

# Solution:

This solution is to build a custom table that allows user to link SL AP invoices to JB invoices. Then, the JB invoices becomes a part of the compliance of the SL AP invoices: they will only be open to pay after the JB invoices have been paid. 

## Notes:

### **General Process**:

Situation 1: if the linked SL AP invoice exists before the JB invoice is created

Process: AP Entry --> JB Progress Bill to create bill --> On JB Progress Bill, go to the SL Posted tab, and link the AP invoices and fill percent complete on those AP invoices --> interface the JB bill --> if you need to make changes to percent complete or link it to a different JB invoice, go to JB progress bill to change the invoice status to 'Change', and make changes on the SL Posted tab --> AP invoices compliances are met and the JB invoice is paid --> the AP invoice is released from hold and open to pay --> Once paid, the record will be deleted from the custom table and insert into a different custom table for keeping the record

Situation 2: if the linked SL AP invoice exists after the JB invoice is created

Process: On AP entry, fill custom fields with the linked JB invoice info --> After posting the AP entry, the AP invoice is tied to the JB invoice --> if you need to make changes to percent complete or link it to a different JB invoice, go to JB progress bill to change the invoice status to 'Change', and make changes on the SL Posted tab --> AP invoices compliances are met and the JB invoice is paid --> the AP invoice is released from hold and open to pay --> Once paid, the record will be deleted from the custom table and insert into a different custom table for keeping the record

The custom table example:

**JB Progress Bill SL Posted**

![image](https://user-images.githubusercontent.com/99040873/168122670-c7f2f59a-2b6d-4458-b385-5bd1065b1697.png)

![image](https://user-images.githubusercontent.com/99040873/176796293-833344c6-c545-47dd-b966-74616dfa7800.png)


**JB Bill SL Posted History**

![image](https://user-images.githubusercontent.com/99040873/176796402-70984e4d-a143-4125-93f2-397ba0a7ba31.png)


**SL APHB Invoice Compliance**

![image](https://user-images.githubusercontent.com/99040873/176796492-7d709b34-ca8b-4745-984b-9b14cce4e5df.png)


**SL APUI Invoice Compliance**
![image](https://user-images.githubusercontent.com/99040873/176796573-1f137559-167c-460e-a70e-5c3d89133b66.png)


**SL AP Invoice Compliance**
![image](https://user-images.githubusercontent.com/99040873/176796528-26d40330-8f8f-46af-b017-17a84e06000f.png)


