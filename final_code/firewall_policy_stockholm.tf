# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- root/firewall_policy_stockholm.tf ---

resource "aws_networkfirewall_firewall_policy" "stockholm_anfw_policy" {
  provider = aws.awsstockholm

  name = "firewall-policy-${var.identifier}"

  firewall_policy {

    # Stateless configuration
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateless_rule_group_reference {
      priority     = 10
      resource_arn = aws_networkfirewall_rule_group.stockholm_drop_remote.arn
    }

    # Stateful configuration
    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
    stateful_default_actions = ["aws:drop_strict", "aws:alert_strict"]
    stateful_rule_group_reference {
      priority     = 20
      resource_arn = aws_networkfirewall_rule_group.stockholm_allow_domains.arn
    }
  }
}

# Stateless Rule Group - Dropping any SSH or RDP connection
resource "aws_networkfirewall_rule_group" "stockholm_drop_remote" {
  provider = aws.awsstockholm

  capacity = 2
  name     = "drop-remote-${var.identifier}"
  type     = "STATELESS"
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {

        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {
              protocols = [6]
              source {
                address_definition = "0.0.0.0/0"
              }
              source_port {
                from_port = 22
                to_port   = 22
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
              destination_port {
                from_port = 22
                to_port   = 22
              }
            }
          }
        }

        stateless_rule {
          priority = 2
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {
              protocols = [27]
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }
}

# Stateful Rule Group - Allowing access to .amazon.com (HTTPS)
resource "aws_networkfirewall_rule_group" "stockholm_allow_domains" {
  provider = aws.awsstockholm

  capacity = 100
  name     = "allow-domains-${var.identifier}"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_string = <<EOF
      pass tcp any any <> $EXTERNAL_NET 443 (msg:"Allowing TCP in port 443"; flow:not_established; sid:892123; rev:1;)
      pass tls any any -> $EXTERNAL_NET 443 (tls.sni; dotprefix; content:".amazon.com"; endswith; msg:"Allowing .amazon.com HTTPS requests"; sid:892125; rev:1;)
      EOF
    }
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }
}