# Project

This lab guides you through a series of practical exercises focused on modernising Zava's business applications and databases by migrating everything to Azure, leveraging GitHub Enterprise, Copilot, and Azure services. Each exercise is designed to deliver hands-on experience in governance, automation, security, AI integration, and observability, ensuring Zava’s transition to Azure is robust, secure, and future-ready.


## ZavaStorefront Application

The ZavaStorefront is a .NET 6.0 web application that can be deployed as a containerized application to Azure App Service.

### Azure Infrastructure

The application infrastructure is defined using Bicep templates and can be deployed to Azure using Azure Developer CLI (azd). The infrastructure includes:

- **Azure Container Registry (ACR)** - For storing Docker container images
- **App Service (Linux)** - For hosting the containerized web application
- **Application Insights** - For monitoring and telemetry
- **Azure AI Services** - For GPT-4 and Phi model access
- **Managed Identity** - For secure, password-less authentication

For detailed deployment instructions, see [Infrastructure Documentation](./infra/README.md).

### Quick Start

1. **Deploy Infrastructure**:
   ```bash
   azd auth login
   azd provision
   ```

2. **Deploy Application**:
   ```bash
   azd deploy
   ```

3. **Access the Application**:
   ```bash
   azd show
   ```

For more information, see the [Infrastructure README](./infra/README.md).

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
