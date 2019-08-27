
Class CacheDataService: ICacheDataService {

    $cacheRepository = $null;

    CacheDataService([ICacheRepository] $cacheRepository) {
        $this.cacheRepository = $cacheRepository;
    }
        
    [void] SetByKey([string] $key, [object] $value) {
        
        # converting the object to string
        $valueType = $value.GetType().ToString();
        
        # Adding .Contains("System.Collections.Generic.Dictionary") because
        # Azure deployment outputs is of type of Generic.Dictionary[Sdk.OutputVariables]
        if (($valueType -eq "System.Collections.Hashtable") -or `
            ($valueType.Contains("System.Collections.Generic.Dictionary")) -or `
            ($valueType -eq "System.Management.Automation.PSCustomObject") -or `
            ($valueType -eq "System.Object[]") -or `
            ($valueType -eq "System.Object")) {
            $cacheValue = `
                ConvertTo-Json `
                    -InputObject $value `
                    -Compress `
                    -Depth 100;
        }
        else {
            $cacheValue = $value;
        }
        
        # call repository to store the cache
        $this.cacheRepository.Set(
            $key, 
            $cacheValue);
    }

    [object] GetByKey([string] $key) {
        # Retrieve the value from cache using key
        $cache = `
            $this.cacheRepository.GetByKey($key);

        if ($cache) {
            
            # If we can convert to object, then return converted object 
            # else return string
            Try {
                $cache = `
                    ConvertFrom-Json `
                        -AsHashtable `
                        -InputObject $cache `
                        -Depth 50;
            }
            Catch {
                # No action item if an error is thrown. This is because Test-Json
                # does not correctly check all string for Json conversion. Some strings
                # that are convertible to Json fails Test-Json check. So, we need to rely
                # on ConvertFrom-Json directly instead of using Test-Json to check and 
                # then calling ConvertFrom-Json. However doing so will result in exception
                # being thrown by ConvertFrom-Json if an invalid string is passed.
            }
            return $cache;
        }
        else {
            return $null;
        }
    }

    [void] RemoveByKey([string] $key) {
        $this.cacheRepository.RemoveByKey($key);
    }

    [void] Flush() {
        $this.cacheRepository.Flush();
    }

    [array] GetAll() {
        return $this.cacheRepository.GetAll();
    }
}