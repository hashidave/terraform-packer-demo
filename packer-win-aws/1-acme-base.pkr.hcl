#--------------------------------------------------
# Packer Plugins
#--------------------------------------------------
packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

#--------------------------------------------------
# Common Image Metadata
#--------------------------------------------------
variable "hcp_bucket_name" {
  default = "windows-base"
}

variable "image_name" {
  default = "windows-base"
}

variable "version" {
  default = "1.0.0"
}

#--------------------------------------------------
# AWS Image Config and Definition
#--------------------------------------------------
variable "aws_region" {
  default = "us-east-2"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }


# PUll out the Administrator Password from Vault
local "LocalAdminPw"{
  expression =  vault ("kv/data/PackerDemo", "LocalAdminPW")
  sensitive = true
}

source "amazon-ebs" "firstrun-windows" {
  region = var.aws_region
  instance_type  = "t2.micro"
  communicator="winrm"
  ami_name       = "packer-windows-${var.version}-${local.timestamp}"
  
  source_ami_filter {
    filters={
      name = "Windows_Server-2012-R2*English-64Bit-Base*"
      root-device-type="ebs"  
      virtualization-type="hvm"
    }
    most_recent = true
    owners = ["amazon"]
  }

  user_data_file="./bootstrap_win.txt"
  #winrm_password= "${local.LocalAdminPw}"
  winrm_password="SuperS3cr3t!!!!"
  winrm_username="Administrator"

}



#--------------------------------------------------
# Common Build Definition
#--------------------------------------------------
build {

  hcp_packer_registry {
    bucket_name = var.hcp_bucket_name
    description = <<EOT
This is the base Windows image + Our "Platform"
    EOT
    bucket_labels = {
      "owner"          = "platform-team"
      "os"             = "Windows Server 2021"
      "image-name"     = var.image_name
    }

    build_labels = {
      "build-time"        = "${local.timestamp}"
      "build-source"      = basename(path.cwd)
      "acme-base-version" = var.version
    }
  }

  sources = [
    "source.amazon-ebs.firstrun-windows"
  ]

  provisioner "powershell"{
    environment_vars=["DEVOPS_LIFE_IMPROVER=PACKER"]
    inline           = ["Write-Host \"HELLO NEW USER; WELCOME TO $Env:DEVOPS_LIFE_IMPROVER\"", "Write-Host \"You need to use backtick escapes when using\"", "Write-Host \"characters such as DOLLAR`$ directly in a command\"", "Write-Host \"or in your own scripts.\"", "[System.Environment]::SetEnvironmentVariable('Foo','Bar')"]
  }
  provisioner "windows-restart" {
  }
  provisioner "powershell" {
    environment_vars = ["VAR1=A$Dollar", "VAR2=A`Backtick", "VAR3=A'SingleQuote", "VAR4=A\"DoubleQuote"]
    script           = "./sample_script.ps1"
  }

  # The last thing to do is set the local Administrator password to whatever is 
  # stored in Vault
  provisioner "windows-shell"{
    inline = ["net user Administrator ${local.LocalAdminPw}"
              
    ]
  }
}
