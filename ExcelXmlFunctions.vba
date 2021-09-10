
Public Function XMLSTR(cellValue)
    Dim findList As Variant
    Dim replaceList As Variant
    findList = Array("&", "<", ">", "'", """", "$", Chr(13), Chr(10))
    replaceList = Array("&amp;", "&lt;", "&gt;", "&apos;", "&quot;", "&#36;", ", ", ", ")
    For x = LBound(findList) To UBound(findList)
        cellValue = Application.WorksheetFunction.Substitute(cellValue, findList(x), replaceList(x))
    Next x
    XMLSTR = cellValue
End Function

