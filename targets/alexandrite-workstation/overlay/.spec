Name:           
Version:        
Release:        1
Summary:        
License:        
Group:          
Url:            
Source:         root.tar.xz


# Needed for directory ownership
BuildArch:      x86_64



%description


%prep
%autosetup -n root

%build


%install
cp -r %{buildroot}/*

%files
%dir /*
/*



%changelog

