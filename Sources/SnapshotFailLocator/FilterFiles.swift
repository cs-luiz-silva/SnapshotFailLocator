import Foundation

/// Filter files in a given repository using a given match string.
func filterFiles(in repository: SnapshotRepository, with string: String) -> [SnapshotFile] {
    enum FilterStyle {
        case contains
        case fnmatch
    }
    
    let style: FilterStyle
    
    // Plain alpha-numeric: Do simple 'contains' filter
    if string.rangeOfCharacter(from: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "+-")).inverted) == nil {
        style = .contains
    } else {
        // Any other character
        style = .fnmatch
    }
    
    let files = repository.files
    
    let result = files.filter { snapshot in
        let segment = snapshot.failurePath.pathComponents.suffix(2).joined(separator: "/")
        
        switch style {
        case .contains:
            return segment.localizedCaseInsensitiveContains(string)
            
        case .fnmatch:
            let fnflags = FNM_CASEFOLD
            return fnmatch(string, segment, fnflags) == 0
        }
    }
    
    return result
}
