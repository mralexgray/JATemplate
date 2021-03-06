#import <Foundation/Foundation.h>
#import "JATemplate.h"
#import "JATConstructFuzzTest.h"

NSString * const kJATBenignFuzzerWarningException = @"se.ayton.jens.jatemplate warning occurred";


// If set, prints the first 25 templates and then exits.
#define DUMP_EXAMPLE_TEMPLATES	0


static void ReportException(NSException *ex, NSString *template, NSDictionary *parameters);

#define Print(TEMPLATE, ...)   fputs([JATExpandLiteral(TEMPLATE, ##__VA_ARGS__) UTF8String], stdout)
#define EPrint(TEMPLATE, ...)  fputs([JATExpandLiteral(TEMPLATE, ##__VA_ARGS__) UTF8String], stderr)


int main(int argc, const char * argv[])
{
	srandomdev();
	
	@autoreleasepool
	{
		Print(@"Starting fuzz testing...\n");
		
		NSUInteger count = 0;
		
		@try
		{
			for (;;)
			{
				@autoreleasepool
				{
					count++;
					
					NSString *template;
					NSDictionary *parameters;
					bool OK = JATConstructFuzzTest(&template, &parameters);
					
					if (!OK)
					{
						EPrint(@"Failed to construct test case number {count}.", @(count));
						return EXIT_FAILURE;
					}
					
					#if DUMP_EXAMPLE_TEMPLATES
						Print(@"{template}\n\n", template);
						if (count == 25)  exit(0);
					#endif
					
					@try
					{
						(void)JATExpandLiteralWithParameters(template, parameters);
					}
					@catch (NSException *ex)
					{
						ReportException(ex, template, parameters);
						return EXIT_FAILURE;
					}
					
					if ((count % 1000) == 0)
					{
						Print(@"{count} happy customers served.\n", @(count));
					}
				}
			}
		}
		@catch (NSException *ex)
		{
			NSString *name = ex.name;
			NSString *reason = ex.reason;
			
			EPrint(@"An exception occurred outside of template expansion.\n\nException: {name}\n\nReason: {reason}\n", name, reason);
			return EXIT_FAILURE;
		}
	}
}


void JATWarnIntercept(NSString *message)
{
	[NSException raise:kJATBenignFuzzerWarningException format:@"%@", message];
}


static void ReportException(NSException *ex, NSString *template, NSDictionary *parameters)
{
	if ([ex.name isEqual:kJATBenignFuzzerWarningException])
	{
		NSString *warning = ex.reason;
		
		EPrint(@"An unexpected warning occurred during template expansion. This may be a bug in JATemplate, or a bug in the test case constructor.\n\nWarning text: {warning}\n\nTemplate: {template}\n\nParameters: {parameters}\n", warning, template, parameters);
	}
	else
	{
		NSString *name = ex.name;
		NSString *reason = ex.reason;
		
		EPrint(@"An exception occurred during template expansion.\n\nException: {name}\n\nReason: {reason}\n", name, reason);
	}
}
